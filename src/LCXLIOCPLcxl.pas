unit LCXLIOCPLcxl;

interface

uses
  Windows, Sysutils, LCXLIOCPBase;

type
  TSendDataRec = record
  private
    TotalLen: LongWord;
    TotalData: Pointer;
  public
    Data: Pointer;
    DataLen: LongWord;
  end;
  PSendDataRec = ^TSendDataRec;

  TLLSockLst = class(TSocketLst)
  protected
    procedure CreateSockObj(var SockObj: TSocketObj); override; // ����
  end;

  // LCXLЭ���socket��
  TLLSockObj = class(TSocketObj)
  private
    FIsRecvLen: Boolean; // �Ƿ��ڽ������ݳ���
    FBuf: Pointer;
    FCurDataLen: LongWord;
    FNeedDataLen: LongWord;
    FBufLen: LongWord;
  protected
    // ��ʼ��
    function Init(): Boolean; override;
    function GetRecvData: Pointer; virtual;
    function GetRecvDataLen: LongWord; virtual;
    property RecvBuf: Pointer read FBuf;
  public
    // ����
    destructor Destroy; override;
    // SendData֮ǰ����
    function SendData(const SendDataRec: TSendDataRec): Boolean; reintroduce; overload;
    function SendData(Data: Pointer; DataLen: LongWord): Boolean; reintroduce; overload;
    //��ȡ�������ݵ�ָ��
    procedure GetSendData(DataLen: LongWord; var SendDataRec: TSendDataRec); reintroduce;
    //ֻ��û�е���SendData��ʱ��ſ����ͷţ�����SendData֮�󽫻��Զ��ͷš�
    procedure FreeSendData(const SendDataRec: TSendDataRec);reintroduce;

    property RecvData: Pointer read GetRecvData;
    property RecvDataLen: LongWord read GetRecvDataLen;
    property IsRecvLen: Boolean read FIsRecvLen;

  end;

  // IOCP�¼�
  TOnLCXLEvent = procedure(EventType: TIocpEventEnum; SockObj: TLLSockObj;
    Overlapped: PIOCPOverlapped) of object;

  // LCXLЭ��ʵ����
  TIOCPLCXLList = class(TIOCPBaseList)
  private
    FIOCPEvent: TOnLCXLEvent;
    FListenEvent: TOnListenEvent;
  protected
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); override;
    // �����¼�
    procedure OnListenEvent(EventType: TListenEventEnum;
      SockLst: TSocketLst); override;
  public
    // �ⲿ�ӿ�
    property IOCPEvent: TOnLCXLEvent read FIOCPEvent write FIOCPEvent;
    property ListenEvent: TOnListenEvent read FListenEvent write FListenEvent;
  end;

implementation

{ TLLSockObj }

destructor TLLSockObj.Destroy;
begin
  if FBuf <> nil then
  begin
    FreeMem(FBuf);
  end;
  inherited;
end;

procedure TLLSockObj.FreeSendData(const SendDataRec: TSendDataRec);
begin
  inherited FreeSendData(SendDataRec.TotalData);
end;

function TLLSockObj.GetRecvData: Pointer;
begin
  if FIsRecvLen then
  begin
    Result := nil;
  end
  else
  begin
    Result := FBuf;
  end;
end;

function TLLSockObj.GetRecvDataLen: LongWord;
begin
  if FIsRecvLen then
  begin
    Result := 0;
  end
  else
  begin
    Result := FCurDataLen;
  end;
end;

procedure TLLSockObj.GetSendData(DataLen: LongWord;
  var SendDataRec: TSendDataRec);
begin
  SendDataRec.TotalLen := DataLen+SizeOf(DataLen);
  SendDataRec.TotalData := inherited GetSendData(SendDataRec.TotalLen);
  PLongWord(SendDataRec.TotalData)^ := DataLen;
  SendDataRec.DataLen := DataLen;
  SendDataRec.Data := PByte(SendDataRec.TotalData)+SizeOf(DataLen);
end;

function TLLSockObj.Init: Boolean;
begin
  // �ȵ��ø����Init����
  Result := inherited;
  // ����Ϊ�������ݵĳ���
  FIsRecvLen := True;
  FCurDataLen := 0;
  FNeedDataLen := SizeOf(FNeedDataLen);
  FBufLen := 1024;
  GetMem(FBuf, FBufLen);
  //SetKeepAlive(True);
end;

function TLLSockObj.SendData(Data: Pointer; DataLen: LongWord): Boolean;
var
  SendRec: TSendDataRec;
begin
  GetSendData(DataLen, SendRec);
  CopyMemory(SendRec.Data, Data, DataLen);
  Result := SendData(SendRec);
end;

function TLLSockObj.SendData(const SendDataRec: TSendDataRec): Boolean;
begin
  Result := inherited SendData(SendDataRec.TotalData,
    SendDataRec.TotalLen, True);
end;

{ TIOCPOBJLCXL }

procedure TIOCPLCXLList.OnIOCPEvent(EventType: TIocpEventEnum;
  SockObj: TSocketObj; Overlapped: PIOCPOverlapped);
var
  LLSockObj: TLLSockObj absolute SockObj;
  DataLen: LongWord;
  NewNeedDataLen: LongWord;
begin
  case EventType of
    ieRecvAll:
      begin
        DataLen := LLSockObj.FCurDataLen + Overlapped.GetRecvDataLen;
        // ���������ڴ�
        if DataLen > LLSockObj.FBufLen then
        begin
          LLSockObj.FBufLen := DataLen;
          ReallocMem(LLSockObj.FBuf, LLSockObj.FBufLen);
        end;
        CopyMemory(Pbyte(LLSockObj.FBuf) + LLSockObj.FCurDataLen,
          Overlapped.GetRecvData, Overlapped.GetRecvDataLen);
        while LLSockObj.FNeedDataLen <= DataLen do
        begin
          LLSockObj.FCurDataLen := LLSockObj.FNeedDataLen;
          if LLSockObj.FIsRecvLen then
          begin
            // ��ȡ����
            if Assigned(FIOCPEvent) then
            begin
              FIOCPEvent(ieRecvPart, LLSockObj, Overlapped);
            end;
            NewNeedDataLen := PLongWord(LLSockObj.FBuf)^;
            
          end
          else
          begin

            if Assigned(FIOCPEvent) then
            begin
              FIOCPEvent(ieRecvAll, LLSockObj, Overlapped);
            end;
            NewNeedDataLen := SizeOf(LLSockObj.FNeedDataLen);
          end;

          DataLen := DataLen - LLSockObj.FNeedDataLen;
          MoveMemory(LLSockObj.FBuf, Pbyte(LLSockObj.FBuf) +
            LLSockObj.FNeedDataLen, DataLen);

          LLSockObj.FNeedDataLen := NewNeedDataLen;
          LLSockObj.FIsRecvLen := not LLSockObj.FIsRecvLen;

        end;
        LLSockObj.FCurDataLen := DataLen;
        (*
        if (LLSockObj.FCurDataLen <= 4096) and
          (LLSockObj.FBufLen >= (4096 shl 3)) then
        begin
          LLSockObj.FBufLen := 4096;
          GetMem(P, LLSockObj.FBufLen);
          CopyMemory(P, LLSockObj.FBuf, LLSockObj.FCurDataLen);
          FreeMem(LLSockObj.FBuf);
          LLSockObj.FBuf := P;
        end;
        *)
      end;
  else
    if Assigned(FIOCPEvent) then
    begin
      FIOCPEvent(EventType, LLSockObj, Overlapped);
    end;
  end;

end;

procedure TIOCPLCXLList.OnListenEvent(EventType: TListenEventEnum;
  SockLst: TSocketLst);
begin
  if Assigned(FListenEvent) then
  begin
    FListenEvent(EventType, SockLst);
  end;

end;

{ TLLSockLst }

procedure TLLSockLst.CreateSockObj(var SockObj: TSocketObj);
begin
  SockObj := TLLSockObj.Create;

end;

end.
