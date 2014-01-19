unit LCXLIOCPLcxl;

interface

uses
  Windows, Sysutils, LCXLIOCPBase;

type
  TSendDataRec = record
  private
    FTotalLen: LongWord;
    FTotalData: Pointer;
    FData: Pointer;
    FDataLen: LongWord;
  public
    property Data: Pointer read FData;
    property DataLen: LongWord read FDataLen;
    /// <summary>
    /// ������������ת��Ϊ����¼�����ݽṹ
    /// </summary>
    function Assgin(_TotalData: Pointer; _TotalLen: LongWord): Boolean;

  end;

  PSendDataRec = ^TSendDataRec;

  TLLSockLst = class(TSocketLst)
  protected
    procedure CreateSockObj(var SockObj: TSocketObj); override; // ����
  end;

  ///	<summary>
  ///	  LCXLЭ���socket��
  ///	</summary>
  TLLSockObj = class(TSocketObj)
  private
    FBuf: Pointer;
    FCurDataLen: LongWord;
    FBufLen: LongWord;
    /// <summary>
    /// ���յ�������
    /// </summary>
    FRecvData: Pointer;
    FRecvDataLen: LongWord;
    /// <summary>
    /// �Ƿ����һ������������
    /// </summary>
    FIsRecvAll: Boolean;
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
    // ��ȡ�������ݵ�ָ��
    procedure GetSendData(DataLen: LongWord; var SendDataRec: TSendDataRec); reintroduce;
    // ֻ��û�е���SendData��ʱ��ſ����ͷţ�����SendData֮�󽫻��Զ��ͷš�
    procedure FreeSendData(const SendDataRec: TSendDataRec); reintroduce;

    property RecvData: Pointer read GetRecvData;
    property RecvDataLen: LongWord read GetRecvDataLen;
    property IsRecvAll: Boolean read FIsRecvAll;

  end;

  // LCXLЭ��ʵ����
  TCustomIOCPLCXLList = class(TCustomIOCPBaseList)
  private
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped);overload; override;
  protected
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TLLSockObj;
      Overlapped: PIOCPOverlapped);overload; virtual;
  end;

  // IOCP�¼�
  TOnIOCPLCXLEvent = procedure(EventType: TIocpEventEnum; SockObj: TLLSockObj;
    Overlapped: PIOCPOverlapped) of object;
  TOnListenLCXLEvent = procedure(EventType: TListenEventEnum; SockLst: TLLSockLst) of object;

  // LCXLЭ��ʵ����
  TIOCPLCXLList = class(TCustomIOCPLCXLList)
  private
    FIOCPEvent: TOnIOCPLCXLEvent;
    FListenEvent: TOnListenLCXLEvent;
  protected
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TLLSockObj;
      Overlapped: PIOCPOverlapped); override;
    // �����¼�
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); override;
  public
    // �ⲿ�ӿ�
    property IOCPEvent: TOnIOCPLCXLEvent read FIOCPEvent write FIOCPEvent;
    property ListenEvent: TOnListenLCXLEvent read FListenEvent write FListenEvent;
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
  inherited FreeSendData(SendDataRec.FTotalData);
end;

function TLLSockObj.GetRecvData: Pointer;
begin
  if not FIsRecvAll then
  begin
    Result := nil;
  end
  else
  begin
    Result := FRecvData;
  end;
end;

function TLLSockObj.GetRecvDataLen: LongWord;
begin
  if not FIsRecvAll then
  begin
    Result := 0;
  end
  else
  begin
    Result := FRecvDataLen;
  end;
end;

procedure TLLSockObj.GetSendData(DataLen: LongWord; var SendDataRec: TSendDataRec);
var
  IsSuc: Boolean;
begin
  SendDataRec.FTotalLen := DataLen + SizeOf(DataLen);
  SendDataRec.FTotalData := inherited GetSendData(SendDataRec.FTotalLen);
  PLongWord(SendDataRec.FTotalData)^ := DataLen;

  IsSuc := SendDataRec.Assgin(SendDataRec.FTotalData, SendDataRec.FTotalLen);
  Assert(IsSuc=True);
end;

function TLLSockObj.Init: Boolean;
begin
  // �ȵ��ø����Init����
  Result := inherited;
  // ����Ϊ�������ݵĳ���
  FIsRecvAll := False;
  FCurDataLen := 0;
  FBufLen := 1024;
  GetMem(FBuf, FBufLen);
  // SetKeepAlive(True);
end;

function TLLSockObj.SendData(Data: Pointer; DataLen: LongWord): Boolean;
var
  SendRec: TSendDataRec;
begin
  GetSendData(DataLen, SendRec);
  CopyMemory(SendRec.Data, Data, DataLen);
  Result := SendData(SendRec);
  if not Result then
  begin
    FreeSendData(SendRec);
  end;
end;

function TLLSockObj.SendData(const SendDataRec: TSendDataRec): Boolean;
begin
  Result := inherited SendData(SendDataRec.FTotalData, SendDataRec.FTotalLen, True);
end;

{ TIOCPOBJLCXL }

procedure TIOCPLCXLList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TLLSockObj;
  Overlapped: PIOCPOverlapped);
var
  LLSockObj: TLLSockObj absolute SockObj;
begin
  if Assigned(FIOCPEvent) then
  begin
    FIOCPEvent(ieRecvAll, SockObj, Overlapped);
  end;
end;

procedure TIOCPLCXLList.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
var
  LLSockLst: TLLSockLst absolute SockLst;
begin
  if Assigned(FListenEvent) then
  begin
    FListenEvent(EventType, LLSockLst);
  end;

end;

{ TLLSockLst }

procedure TLLSockLst.CreateSockObj(var SockObj: TSocketObj);
begin
  SockObj := TLLSockObj.Create;

end;

{ TSendDataRec }

function TSendDataRec.Assgin(_TotalData: Pointer; _TotalLen: LongWord): Boolean;
begin
  Result := False;
  if (_TotalLen < SizeOf(LongWord)) or (PLongWord(_TotalData)^ <> _TotalLen - SizeOf(LongWord)) then
  begin
    Exit;
  end;
  FTotalData := _TotalData;
  FTotalLen := _TotalLen;

  FData := Pointer(PByte(FTotalData) + SizeOf(LongWord));
  FDataLen := FTotalLen - SizeOf(LongWord);
  Result := True;
end;

{ TCustomIOCPLCXLList }

procedure TCustomIOCPLCXLList.OnIOCPEvent(EventType: TIocpEventEnum;
  SockObj: TSocketObj; Overlapped: PIOCPOverlapped);
var
  LLSockObj: TLLSockObj absolute SockObj;
begin
  case EventType of
    ieRecvAll:
      begin

        // ���������ڴ�
        if LLSockObj.FCurDataLen + Overlapped.GetRecvDataLen > LLSockObj.FBufLen then
        begin
          LLSockObj.FBufLen := LLSockObj.FCurDataLen + Overlapped.GetRecvDataLen;
          ReallocMem(LLSockObj.FBuf, LLSockObj.FBufLen);
        end;
        CopyMemory(PByte(LLSockObj.FBuf) + LLSockObj.FCurDataLen, Overlapped.GetRecvData,
          Overlapped.GetRecvDataLen);
        LLSockObj.FCurDataLen := LLSockObj.FCurDataLen + Overlapped.GetRecvDataLen;
        while (LLSockObj.FCurDataLen >= SizeOf(LongWord)) and
          (LLSockObj.FCurDataLen - SizeOf(LongWord) >= PLongWord(LLSockObj.FBuf)^) do
        begin

          LLSockObj.FRecvData := LLSockObj.FBuf;
          LLSockObj.FRecvDataLen := PLongWord(LLSockObj.FBuf)^ + SizeOf(LongWord);
          LLSockObj.FIsRecvAll := True;
          OnIOCPEvent(ieRecvAll, LLSockObj, Overlapped);

          LLSockObj.FIsRecvAll := False;
          MoveMemory(LLSockObj.FBuf, PByte(LLSockObj.FBuf) + LLSockObj.FRecvDataLen,
            LLSockObj.FCurDataLen - LLSockObj.FRecvDataLen);

          LLSockObj.FCurDataLen := LLSockObj.FCurDataLen - LLSockObj.FRecvDataLen;

        end;
        if LLSockObj.FCurDataLen > 0 then
        begin
          OnIOCPEvent(ieRecvPart, LLSockObj, Overlapped);
        end;
      end;
  else
    OnIOCPEvent(EventType, LLSockObj, Overlapped);
  end;
end;

procedure TCustomIOCPLCXLList.OnIOCPEvent(EventType: TIocpEventEnum;
  SockObj: TLLSockObj; Overlapped: PIOCPOverlapped);
begin
  //nothing
end;

end.
