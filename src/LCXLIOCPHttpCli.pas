unit LCXLIOCPHttpCli;
(* **************************************************************************** *)
(* ����: LCXL *)
(* E-mail: lcx87654321@163.com *)
(* ˵��: IOCP Http�ͻ��˶����� *)
(* **************************************************************************** *)
interface

uses
  Windows, Sysutils, Classes, LCXLIOCPBase, LCXLHttpComm, IniFiles, LCXLIOCPHttp;

type
  TIOCPHttpClientList = class;

  THttpCliObj = class(THttpBaseObj)
  private
    FData: Pointer;
    FDataLen: LongWord;
    function RequesttoBinData(HttpRequest: THttpRequest; var BinData: Pointer;
      var BinDataLen: LongWord): Boolean;
  public
    destructor Destroy(); override;
    // ������������������������ظ�����
    function SendRequest(): Boolean;
  end;

  TCustomIOCPHttpClientList = class(TIOCPHttpBaseList)
  protected
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); override;
  protected
    procedure OnHTTPRecvHeadCompleted(HttpObj: THttpCliObj);virtual;abstract;
    procedure OnHTTPRecvCompleted(HttpObj: THttpCliObj);virtual;abstract;
    procedure OnHTTPRecvError(HttpObj: THttpCliObj);virtual;abstract;
    procedure OnHTTPClose(HttpObj: THttpCliObj);virtual;abstract;
    procedure OnHTTPRecving(HttpObj: THttpCliObj; RecvDataLen: Integer);virtual;abstract;
  end;

  TOnHTTPRecvHeadCompletedEvent = procedure(HttpObj: THttpCliObj) of object;
  TOnHTTPRecvCompletedEvent = procedure(HttpObj: THttpCliObj) of object;
  TOnHTTPRecvErrorEvent = procedure(HttpObj: THttpCliObj) of object;
  TOnHTTPCloseEvent = procedure(HttpObj: THttpCliObj) of object;
  TOnHTTPRecvingEvent = procedure(HttpObj: THttpCliObj; RecvDataLen: Integer) of object;

  TIOCPHttpClientList = class(TCustomIOCPHttpClientList)
  private
    // �¼�
    FHTTPRecvHeadCompletedEvent: TOnHTTPRecvHeadCompletedEvent;
    FHTTPRecvCompletedEvent: TOnHTTPRecvCompletedEvent;
    FHTTPRecvErrorEvent: TOnHTTPRecvErrorEvent;
    FHTTPCloseEvent: TOnHTTPCloseEvent;
    FHTTPRecvingEvent: TOnHTTPRecvingEvent;
  protected
    procedure OnHTTPRecvHeadCompleted(HttpObj: THttpCliObj);override;
    procedure OnHTTPRecvCompleted(HttpObj: THttpCliObj);override;
    procedure OnHTTPRecvError(HttpObj: THttpCliObj);override;
    procedure OnHTTPClose(HttpObj: THttpCliObj);override;
    procedure OnHTTPRecving(HttpObj: THttpCliObj; RecvDataLen: Integer);override;
  public
    property HTTPRecvHeadCompletedEvent: TOnHTTPRecvHeadCompletedEvent
      read FHTTPRecvHeadCompletedEvent write FHTTPRecvHeadCompletedEvent;
    property HTTPRecvCompletedEvent: TOnHTTPRecvCompletedEvent
      read FHTTPRecvCompletedEvent write FHTTPRecvCompletedEvent;
    property HTTPRecvErrorEvent: TOnHTTPRecvErrorEvent read FHTTPRecvErrorEvent
      write FHTTPRecvErrorEvent;
    property HTTPCloseEvent: TOnHTTPCloseEvent read FHTTPCloseEvent write FHTTPCloseEvent;
    property HTTPRecvingEvent: TOnHTTPRecvingEvent read FHTTPRecvingEvent
      write FHTTPRecvingEvent;
  end;



implementation

{ THttpObj }

destructor THttpCliObj.Destroy;
begin
  if FData <> nil then
  begin
    FreeMem(FData);
    FData := nil;
  end;
  inherited;
end;

function THttpCliObj.RequesttoBinData(HttpRequest: THttpRequest; var BinData: Pointer;
  var BinDataLen: LongWord): Boolean;
var
  RequestHead: AnsiString;
begin
  Result := False;
  RequestHead := HttpRequest.RequestHead;
  BinDataLen := Length(RequestHead) * sizeof(AnsiChar);
  BinData := GetSendData(BinDataLen);
  if BinData <> nil then
  begin
    CopyMemory(BinData, PAnsiChar(RequestHead), Length(RequestHead) * sizeof(AnsiChar));
    Result := True;
  end;
end;

function THttpCliObj.SendRequest(): Boolean;
var
  ReqData: Pointer;
  ReqDataLen: LongWord;
begin
  Result := False;
  if HttpRequest=nil then
  begin
    raise Exception.Create('FHttpRequest must be set');
  end;

  if HttpResponse=nil then
  begin
    raise Exception.Create('HttpResponse must be set');
  end;

  if RequesttoBinData(HttpRequest, ReqData, ReqDataLen) then
  begin
    if HttpRequest.IsPostMethod then
    begin
      HttpRequest.BeginTransferContent(False);
    end;
    if not SendData(ReqData, ReqDataLen, True) then
    begin
      if HttpRequest.IsPostMethod then
      begin
        HttpRequest.EndTransferContent;
      end;
    end;
  end;
end;

{ TIOCPHttpClientList }

procedure TIOCPHttpClientList.OnHTTPClose(HttpObj: THttpCliObj);
begin
  if Assigned(FHTTPCloseEvent) then
  begin
    FHTTPCloseEvent(HttpObj);
  end;

end;

procedure TIOCPHttpClientList.OnHTTPRecvCompleted(HttpObj: THttpCliObj);
begin
  if Assigned(FHTTPRecvCompletedEvent) then
  begin
    FHTTPRecvCompletedEvent(HttpObj);
  end;
end;

procedure TIOCPHttpClientList.OnHTTPRecvError(HttpObj: THttpCliObj);
begin
  inherited;
  if Assigned(FHTTPRecvErrorEvent) then
  begin
    FHTTPRecvErrorEvent(HttpObj);
  end;
end;

procedure TIOCPHttpClientList.OnHTTPRecvHeadCompleted(HttpObj: THttpCliObj);
begin
  if Assigned(FHTTPRecvHeadCompletedEvent) then
  begin
    FHTTPRecvHeadCompletedEvent(HttpObj);
  end;
end;

procedure TIOCPHttpClientList.OnHTTPRecving(HttpObj: THttpCliObj;
  RecvDataLen: Integer);
begin
  if Assigned(FHTTPRecvingEvent) then
  begin
    FHTTPRecvingEvent(HttpObj, RecvDataLen);
  end;

end;

{ TIOCPCustomHttpClientList }

procedure TCustomIOCPHttpClientList.OnIOCPEvent(EventType: TIocpEventEnum;
  SockObj: TSocketObj; Overlapped: PIOCPOverlapped);
var
  HttpSock: THttpCliObj absolute SockObj;
  HeadTmp: AnsiString;
  HeadEndIndex: Integer;
  DataBeginIndex: Integer;
  SendData: Pointer;
  SendDataLen: DWORD;
begin
  case EventType of
    ieAddSocket:
      ;
    ieDelSocket:
      begin
        if HttpSock.RecvHeadCompleted then
        begin
          if HttpSock.Content_Length < 0 then
          begin
            OnHTTPRecvCompleted(HttpSock);

          end;
        end;
        OnHTTPClose(HttpSock);
      end;
    ieError:
      ;
    ieRecvPart:
      ;
    ieRecvAll:
      begin
        if not HttpSock.RecvHeadCompleted then
        begin
          ReallocMem(HttpSock.FData, HttpSock.FDataLen +
            Overlapped.RecvDataLen);

          CopyMemory(PByte(HttpSock.FData) +
            HttpSock.FDataLen, Overlapped.RecvData, Overlapped.RecvDataLen);
          HttpSock.FDataLen := HttpSock.FDataLen +
            Overlapped.RecvDataLen;
          // ׼�����ҿ���
          SetString(HeadTmp, PAnsiChar(HttpSock.FData),
            HttpSock.FDataLen);

          HeadEndIndex := Pos(DOUBLE_HTTP_LINE_BREAK, HeadTmp);
          // �ҵ�Э��ͷ
          if HeadEndIndex > 0 then
          begin
            //��ȡЭ��ͷ
            Delete(HeadTmp, HeadEndIndex+Length(DOUBLE_HTTP_LINE_BREAK), Length(HeadTmp));
            //����Э��ͷ
            HttpSock.HttpResponse.ResponseHead := HeadTmp;
            // ������������
            DataBeginIndex := HeadEndIndex - 1 +
              Length(HTTP_LINE_BREAK)*2;
            HttpSock.HttpResponse.BeginTransferContent(True);
            if Integer(HttpSock.FDataLen) - DataBeginIndex = 0 then
            begin

            end
            else
            begin
              // д�뵽
              HttpSock.HttpResponse.TransferingContent((PByte(HttpSock.FData) + DataBeginIndex), Integer(HttpSock.FDataLen) - DataBeginIndex);
            end;
            FreeMem(HttpSock.FData);
            HttpSock.FData := nil;
            HttpSock.FDataLen := 0;
            // Э��ͷ�������
            HttpSock.RecvHeadCompleted := True;
            // ��ȡ��Ϣ�峤��(�����)
            HttpSock.Content_Length :=
              StrToIntDef(string(HttpSock.HttpResponse[RESPONSE_CONTENT_LENGTH]), -1);

            OnHTTPRecvHeadCompleted(HttpSock);

          end;
        end
        else
        begin
          HttpSock.HttpResponse.TransferingContent(Overlapped.RecvData, Overlapped.RecvDataLen);
        end;
        OnHTTPRecving(HttpSock, Overlapped.RecvDataLen);

        // �������ͷ���
        if HttpSock.RecvHeadCompleted then
        begin

          if HttpSock.Content_Length >= 0 then
          begin
            // ���������ɣ��򼤻��¼�
            if HttpSock.Content_Length <= Integer(HttpSock.HttpResponse.GetContentLength()) then
            begin
              OnHTTPRecvCompleted(HttpSock);
            end;
          end;
        end;
      end;
    ieRecvFailed:
      begin
        OnHTTPRecvError(HttpSock);
      end;
    ieSendPart:
      ;
    ieSendAll:
      begin
        if HttpSock.HttpRequest.IsPostMethod then
        begin
          SendDataLen := $1000;
          SendData := HttpSock.GetSendData(SendDataLen);
          SendDataLen := HttpSock.HttpRequest.TransferingContent(SendData, SendDataLen);
          if SendDataLen>0 then
          begin
            if not HttpSock.SendData(SendData, SendDataLen, True) then
            begin
              HttpSock.HttpRequest.EndTransferContent;
            end;
          end
          else
          begin
            HttpSock.HttpRequest.EndTransferContent;
          end;
        end;
      end;
    ieSendFailed:
      ;
  end;
end;

end.
