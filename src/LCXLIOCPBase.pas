unit LCXLIOCPBase;

(* **************************************************************************** *)
(* ���ߣ�LCXL *)
(* ���ݣ�IOCP������ *)
(* **************************************************************************** *)
interface

uses
  Windows, SysUtils, Classes, Types, LCXLWinSock2, LCXLMSWSock, LCXLMSTcpIP, LCXLWS2Def,
  LCXLWs2tcpip;

var
  AcceptEx: LPFN_ACCEPTEX;
  GetAcceptExSockaddrs: LPFN_GETACCEPTEXSOCKADDRS;

procedure OutputDebugStr(const DebugInfo: string); inline;

type
  // Iocp�׽����¼�����
  // ieRecvPart �ڱ���Ԫ��û��ʵ�֣���չ��
  TIocpEventEnum = (ieAddSocket, ieDelSocket, ieError, ieRecvPart, ieRecvAll,
    ieRecvFailed, ieSendPart, ieSendAll, ieSendFailed);
  TListenEventEnum = (leAddSockLst, leDelSockLst);
  // ******************* ǰ������ ************************
  TSocketBase = class;
  // �����߳��࣬Ҫʵ�ֲ�ͬ�Ĺ��ܣ���Ҫ�̳в�ʵ��������
  TSocketLst = class;
  // Overlap�ṹ
  PIOCPOverlapped = ^TIOCPOverlapped;
  // Socket��
  TSocketObj = class;
  // Socket�б��࣬Ҫʵ�ֲ�ͬ�Ĺ��ܣ���Ҫ�̳в�ʵ��������
  TIOCPBaseList = class;
  // �ֳ��б����ˡ�����
  TSocketMgr = class;
  // IOCP������
  TIOCPManager = class;
  // *****************************************************

  // ********************* �¼� **************************
  // IOCP�¼�
  TOnIOCPEvent = procedure(EventType: TIocpEventEnum; SockObj: TSocketObj;
    Overlapped: PIOCPOverlapped) of object;
  // �����¼�
  TOnListenEvent = procedure(EventType: TListenEventEnum; SockLst: TSocketLst) of object;

  TSocketBase = class(TObject)
  protected
    // �������˶��ٴΣ���RefCountΪ0ʱ����free��Socket����
    // RefCount=1��ֻ�н���
    // RefCount-1Ϊ��ǰ���ڷ��͵Ĵ���
    FRefCount: Integer;
    // �Ƿ��ʼ����
    FIsInited: Boolean;
    // �׽���
    FSock: TSocket;
    // ��Socket������IOCPOBJBase�ṹ
    // �˴�IOCPOBJRec�ṹ��ָ����ڴ�һ������TsocketObjȫ���ر�ʱ�Ż���Ч
    FSockMgr: TSocketMgr;
    // �˿ھ��
    FIOComp: THandle;
    FTag: UIntPtr;
    //
    // Overlapped
    FAssignedOverlapped: PIOCPOverlapped;
    function Init(): Boolean; virtual; abstract;
  public
    constructor Create; virtual;
    procedure Close(); virtual;
    ///	<summary>
    ///	  �������ü���
    ///	</summary>
    ///	<returns>
    ///	  ���ص�ǰ�����ü���
    ///	</returns>
    function IncRefCount: Integer;
    ///	<summary>
    ///	  �������ü���
    ///	</summary>
    ///	<returns>
    ///	  ���ص�ǰ�����ü���
    ///	</returns>
    function DecRefCount: Integer;


    ///	<summary>
    ///	  socket������
    ///	</summary>
    property SockMgr: TSocketMgr read FSockMgr;

    ///	<summary>
    ///	  socket���
    ///	</summary>
    property Socket: TSocket read FSock;
    property Tag: UIntPtr read FTag write FTag;

    ///	<summary>
    ///	  �Ƿ��Ѿ���ʼ����
    ///	</summary>
    property IsInited: Boolean read FIsInited;
  end;

  // ********************* �ṹ **************************
  // �����̲߳����ṹ��
  TSocketLst = class(TSocketBase)
  private
    // �����Ķ˿ں�
    FPort: Integer;
    // �ܹ��Ľ��ܵ�����
    FLstBuf: Pointer;
    // Recv�������ܴ�С
    FLstBufLen: LongWord;
    // Socket���ӳش�С
    FSocketPoolSize: Integer;
    procedure SetSocketPoolSize(const Value: Integer);
  protected
    function Accept(): Boolean;
    function Init(): Boolean; override;
    procedure CreateSockObj(var SockObj: TSocketObj); virtual; // ����
  public
    constructor Create; override;
    // ����
    destructor Destroy; override;

    ///	<summary>
    ///	  �����˿ں�
    ///	</summary>
    property Port: Integer read FPort;
    ///	<summary>
    ///	  Socket���ӳش�С
    ///	</summary>
    property SocketPoolSize: Integer read FSocketPoolSize write SetSocketPoolSize;
    ///	<summary>
    ///	  ����˿�ʼ����
    ///	</summary>
    function StartListen(IOCPList: TIOCPBaseList; Port: Integer;
      InAddr: u_long = INADDR_ANY): Boolean;
  end;

  TOverlappedTypeEnum = (otRecv, otSend, otListen);

  ///	<summary>
  ///	  OverLap�ṹ
  ///	</summary>
  _IOCPOverlapped = record
    lpOverlapped: TOverlapped;
    DataBuf: TWSABUF;
    // �Ƿ�����ʹ����
    IsUsed: LongBool;
    // OverLap������
    OverlappedType: TOverlappedTypeEnum;

    // ������ SockRec
    AssignedSockObj: TSocketBase;

    function GetRecvData: Pointer;
    function GetRecvDataLen: LongWord;
    function GetCurSendDataLen: LongWord;
    function GetSendData: Pointer;
    function GetTotalSendDataLen: LongWord;

    case TOverlappedTypeEnum of
      otRecv:
        (RecvData: Pointer;
          RecvDataLen: LongWord;
        );
      otSend:
        (
          // ���͵�����
          SendData: Pointer;
          // ��ǰ���͵�����
          CurSendData: Pointer;
          // �������ݵĳ���
          SendDataLen: LongWord;
        );
      otListen:
        (
          // ���ܵ�socket
          AcceptSocket: TSocket;
        );
  end;

  TIOCPOverlapped = _IOCPOverlapped;

  ///	<summary>
  ///	  Socket�࣬һ�����һ���׽���
  ///	</summary>
  TSocketObj = class(TSocketBase)
  private

    // Recv�������ܴ�С
    FRecvBufLen: LongWord;
    // �ܹ��Ľ��ܵ�����
    FRecvBuf: Pointer;
    // �Ƿ��Ǽ�������socket
    FIsSerSocket: Boolean;

    // �Ƿ����ڷ���
    FIsSending: Boolean;
    // ���������ݶ��С�ʹ��FSockMgr������ͬ��������
    FSendDataQueue: TList;
    function WSARecv(): Boolean; {$IFNDEF DEBUG} inline;
{$ENDIF}
    function WSASend(Overlapped: PIOCPOverlapped): Boolean; {$IFNDEF DEBUG} inline;
{$ENDIF}
  protected

    // ��ʼ��
    function Init(): Boolean; override;
  public
    constructor Create(); override;
    // ����
    destructor Destroy; override;

    ///	<summary>
    ///	  ����ָ���������ַ��֧��IPv6
    ///	</summary>
    ///	<param name="IOCPList">
    ///	  Socket�б�
    ///	</param>
    ///	<param name="SerAddr">
    ///	  Ҫ���ӵĵ�ַ
    ///	</param>
    ///	<param name="Port">
    ///	  Ҫ���ӵĶ˿ں�
    ///	</param>
    ///	<returns>
    ///	  �����Ƿ����ӳɹ�
    ///	</returns>
    function ConnectSer(IOCPList: TIOCPBaseList; const SerAddr: string;
      Port: Integer): Boolean;
    ///	<summary>
    ///	  ��ȡԶ��IP
    ///	</summary>
    function GetRemoteIP(): string; {$IFNDEF DEBUG} inline; {$ENDIF}
    ///	<summary>
    ///	  ��ȡԶ�̶˿�
    ///	</summary>
    function GetRemotePort(): Word; {$IFNDEF DEBUG} inline; {$ENDIF}

    ///	<summary>
    ///	  ��ȡ���ܵ�����
    ///	</summary>
    function GetRecvBuf(): Pointer; {$IFNDEF DEBUG} inline; {$ENDIF}

    ///	<summary>
    ///	  ���û���������
    ///	</summary>
    procedure SetRecvBufLenBeforeInit(NewRecvBufLen: DWORD); inline;
    ///	<summary>
    ///	  �������ݣ��� SendData֮ǰ������
    ///	</summary>
    function SendData(Data: Pointer; DataLen: LongWord;
      UseGetSendDataFunc: Boolean = False): Boolean;

    ///	<summary>
    ///	  ��ȡ�������ݵ�ָ��
    ///	</summary>
    function GetSendData(DataLen: LongWord): Pointer;

    ///	<summary>
    ///	  ֻ��û�е���SendData��ʱ��ſ����ͷţ�����SendData֮�󽫻��Զ��ͷš�
    ///	</summary>
    procedure FreeSendData(Data: Pointer);
    //

    ///	<summary>
    ///	  ����������
    ///	</summary>
    procedure SetKeepAlive(IsOn: Boolean; KeepAliveTime: Integer = 50000;
      KeepAliveInterval: Integer = 30000);

    ///	<summary>
    ///	  �Ƿ��Ƿ���˽��ܵ���socket
    ///	</summary>
    property IsSerSocket: Boolean read FIsSerSocket;
  end;

  ///	<summary>
  ///	  �洢Socket�б���࣬����ṹ����Ϊ��ֻ�ܱ���ǰ��TIOCPBaseList��͹�������ʣ��������ֹ����
  ///	</summary>
  TSocketMgr = class(TObject)
  private
    FIOCPMgr: TIOCPManager;
    // IOCPBase��
    // ���IOCPBase��ΪNIL����˵����IOCPBase�Ѿ�Free�������Ե�SockRecListΪ0��ʱ��
    // Ӧ�ý��˽ṹ���б����Ƴ���Free��
    FIOCPList: TIOCPBaseList;
    FLockRefNum: Integer;
    // Iocp Socket�����Ϣ�̰߳�ȫ�б�
    FSockObjCS: TRTLCriticalSection;
    // �洢TSocketObj��ָ��
    FSockObjList: TList;
    // ��Ӷ����б�
    FSockObjAddList: TList;
    // ɾ�������б�
    FSockObjDelList: TList;
    // �洢TIocpSockAcp��ָ��
    FSockLstList: TList;
    // ��Ӷ����б�
    FSockLstAddList: TList;
    // ɾ�������б�
    FSockLstDelList: TList;
  public
    constructor Create(AIOCPMgr: TIOCPManager); reintroduce; virtual;
    destructor Destroy(); override;

    ///	<summary>
    ///	  ���ֻ�ǵ������ٽ�������Ҫ������Ч�������б�ʹ�� LockSockList
    ///	</summary>
    procedure Lock; {$IFNDEF DEBUG}inline; {$ENDIF}

    ///	<summary>
    ///	  ���ֻ�ǵ������ٽ�����
    ///	</summary>
    procedure Unlock; {$IFNDEF DEBUG}inline; {$ENDIF}

    ///	<summary>
    ///	  �����б�ע����������ܶ��б�������ӣ�ɾ��������һ�ж���SocketMgr��ά��
    ///	</summary>
    procedure LockSockList;
    procedure UnlockSockList;
    // ����TIOCPOBJBase���ã��������ΪNULL�����ʾIOCPObj�Ѿ�������
    function IncIOCPObjRef: TIOCPBaseList; {$IFNDEF DEBUG}inline; {$ENDIF}

    ///	<summary>
    ///	  ����IOCPObj����free��
    ///	</summary>
    procedure SetIOCPObjCanFree;
    // �������ã�������IncIOCPObjRef����ִ�гɹ�ʱִ�У�
    class procedure DecIOCPObjRef(IOCPObj: TIOCPBaseList); {$IFNDEF DEBUG}inline; {$ENDIF}
    // ���SockObj
    function IOCPRegSockBase(SockBase: TSocketBase): Boolean; {$IFNDEF DEBUG}inline;
{$ENDIF}
    // ���sockobj������True��ʾ�ɹ�������False��ʾʧ��
    function AddSockObj(SockObj: TSocketObj): Boolean;
    // �Ƿ�ɹ���ʼ��SockObj
    function InitSockObj(SockObj: TSocketObj): Boolean;
    // ��������
    function IncSockBaseRef(SockBase: TSocketBase): Integer; {$IFNDEF DEBUG}inline;
{$ENDIF}
    // ��������
    class function DecSockBaseRef(SockBase: TSocketBase): Integer; {$IFNDEF DEBUG}inline;
{$ENDIF}
    // �ͷ�sockObj
    class procedure FreeSockObj(SockObj: TSocketObj); {$IFNDEF DEBUG}inline; {$ENDIF}
    // ���SockLst
    function AddSockLst(SockLst: TSocketLst): Boolean; {$IFNDEF DEBUG}inline; {$ENDIF}
    // �ͷ�SockLst
    class procedure FreeSockLst(SockLst: TSocketLst); {$IFNDEF DEBUG}inline; {$ENDIF}
    // ��ѯ�Ƿ�����ͷű��࣬�˺���ֻ���������ڼ����
    function IsCanFree(): Boolean; inline;
  end;

  ///	<summary>
  ///	  IOCP�������
  ///	</summary>
  TIOCPBaseList = class(TObject)
  private
    // �Ƿ�����ͷŴ��ڴ棬��TSocketMgr����
    FCanDestroyEvent: THandle;
    // IOCPObj����
    FSockMgr: TSocketMgr;
    (* ********�������б�����Ҫ�����ٽ���IOCPOBJRec.SockObjCS******** *)
    // �Ƿ�����Ϊ�ͷ�
    FIsFreeing: Boolean;
    // �����ô�����ֻ����FRefCountΪ0��ʱ���������Free�˶���
    FRefCount: Integer;
    (* ************************************************************** *)

    // ���Socket�������ĺ����ӵĶ�����ô˺�����
    function AddSockObj(NewSockObj: TSocketObj): Boolean;
    function AddSockLst(NewSockLst: TSocketLst): Boolean;
  protected
    // IOCP�¼�
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); virtual;
    // �����¼�
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); virtual;

  public
    // ������������Ϊ1.ע������IOCPManager�����У���������һ��Ĭ�ϵ��ڴ���亯��
    constructor Create(AIOCPMgr: TIOCPManager); virtual;
    // ������������Ϊ1.��ע������
    destructor Destroy; override;
    // ������Ϣ������
    procedure ProcessMsgEvent();
    // �ر����е�Socket
    procedure CloseAllSockObj;
    // �ر����е�Socklst
    procedure CloseAllSockLst;
    // ������״̬��ȡSocket�б�
    // ע�⣺������Socket �б�ֻ�ܶ�ȡ�����ܽ���ɾ���Ȳ�����
    procedure LockSockList; inline;
    // ��ȡSocket�б�
    // ע�⣺�ڷ��ʴ�socket�б�֮ǰ�����Ƚ���������
    function GetSockList: TList;
    function GetSockLstList: TList;

    property SockList: TList read GetSockList;
    property SockLstList: TList read GetSockLstList;
    // ����socket�б�
    procedure UnlockSockList; inline;

    // ��ȡ����IP��ַ�б�
    class procedure GetLocalAddrs(Addrs: TStrings);

  end;

  TIOCPBase2List = class(TIOCPBaseList)
  private
    FIOCPEvent: TOnIOCPEvent;
    FListenEvent: TOnListenEvent;
  protected
    // IOCP�¼�
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); override;
    // �����¼�
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); override;
  public
    // �ⲿ�ӿ�
    property IOCPEvent: TOnIOCPEvent read FIOCPEvent write FIOCPEvent;
    property ListenEvent: TOnListenEvent read FListenEvent write FListenEvent;
  end;

  // IOCP����ģ�͹����࣬һ��������ֻ��һ��ʵ��
  TIOCPManager = class(TObject)
  private
    FwsaData: TWSAData;
    // IOCPBaseRec�ṹ�б�
    FSockMgrList: TList;
    // IOCPBase�����ٽ���
    FSockMgrCS: TRTLCriticalSection;
    // OverLapped�̰߳�ȫ�б�
    FOverLappedList: TList;
    FOverLappedCS: TRTLCriticalSection;
    // ��ɶ˿ھ��
    FCompletionPort: THandle;
    // IOCP�߳̾����̬����
    FIocpWorkThreads: array of THandle;
  protected

    // ɾ��Overlapped�б�
    procedure FreeOverLappedList;
    // ����OverlappedΪδʹ��
    procedure DelOverlapped(UsedOverlapped: PIOCPOverlapped);
    // ��ȡδʹ�õ�Overlapped
    function NewOverlapped(SockObj: TSocketBase; OverlappedType: TOverlappedTypeEnum)
      : PIOCPOverlapped;
    // �˳�����
    function PostExitStatus(): Boolean;
  public
    // ������
    constructor Create(IOCPThreadCount: Integer = 0);
    // ������
    destructor Destroy; override;
    // ע��IOCPBase����TIOCPBase.Create�е���
    function CreateSockMgr(IOCPBase: TIOCPBaseList): TSocketMgr;
    procedure LockSockMgr; inline;
    function GetSockMgrList: TList; inline;
    procedure UnlockSockMgr; inline;

    procedure LockOverLappedList; inline;
    function GetOverLappedList: TList; inline;
    procedure UnlockOverLappedList; inline;
    // �ͷ�IOCPBaseRec
    procedure FreeSockMgr(SockMgr: TSocketMgr);
  end;

implementation

procedure OutputDebugStr(const DebugInfo: string);
begin
{$IFDEF DEBUG}
  Windows.OutputDebugString(PChar(Format('%s', [DebugInfo])));
{$ENDIF}
end;

// IOCP�����߳�
function IocpWorkThread(CompletionPortID: Pointer): DWORD; stdcall;
var
  CompletionPort: THandle absolute CompletionPortID;
  BytesTransferred: DWORD;
  resuInt: Integer;

  // CompletionKeyUIntPtr: ULONG_PTR;
  // CompletionKey: TCOMPLETION_KEY_ENUM absolute CompletionKeyUIntPtr;
  SockBase: TSocketBase;
  SockObj: TSocketObj absolute SockBase;
  SockLst: TSocketLst absolute SockBase;
  _NewSockObj: TSocketObj;

  remote: PSOCKADDR;
  local: PSOCKADDR;
  remoteLen: Integer;
  localLen: Integer;

  SockMgr: TSocketMgr;
  FIocpOverlapped: PIOCPOverlapped;
  FIsSuc: Boolean;
  _IOCPObj: TIOCPBaseList;

  _NeedDecSockObj: Boolean;
begin
  while True do
  begin
    // ��ѯ����
    FIsSuc := GetQueuedCompletionStatus(CompletionPort, BytesTransferred,
      ULONG_PTR(SockBase), POverlapped(FIocpOverlapped), INFINITE);
    // ���Ի�ȡSockBase
    if SockBase <> nil then
    begin
      Assert(SockBase = FIocpOverlapped.AssignedSockObj);
    end
    else
    begin
      // IOCP �߳��˳�ָ��
      // �˳�
      OutputDebugStr('����˳�����˳���������һ�߳��˳���');
      // ֪ͨ��һ�������߳��˳�
      PostQueuedCompletionStatus(CompletionPort, 0, 0, nil);
      Break;
    end;
    if FIsSuc then
    begin

      // ������˳��߳���Ϣ�����˳�
      case FIocpOverlapped.OverlappedType of
        otRecv, otSend:
          begin
            if BytesTransferred = 0 then
            begin
              Assert(FIocpOverlapped = SockObj.FAssignedOverlapped);
              OutputDebugStr(Format('socket(%d)�ѹر�:%d ',
                [SockObj.FSock, WSAGetLastError]));
              // ��������
              SockMgr := SockObj.FSockMgr;
              SockMgr.DecSockBaseRef(SockObj);
              // ����
              Continue;
            end;
            // socket�¼�
            // ��ȡIOCPObj�����û��
            _IOCPObj := SockBase.FSockMgr.IncIOCPObjRef;
            case FIocpOverlapped.OverlappedType of

              otRecv:
                begin
                  Assert(FIocpOverlapped = SockObj.FAssignedOverlapped);
                  // �ƶ���ǰ���ܵ�ָ��
                  FIocpOverlapped.RecvDataLen := BytesTransferred;
                  FIocpOverlapped.RecvData := SockObj.FRecvBuf;
                  // ��ȡ�¼�ָ��
                  // ���ͽ��
                  if _IOCPObj <> nil then
                  begin
                    // �����¼�
                    try

                      _IOCPObj.OnIOCPEvent(ieRecvAll, SockObj, FIocpOverlapped);

                    except
                      on E: Exception do
                      begin
                        OutputDebugStr(Format('Message=%s, StackTrace=%s',
                          [E.Message, E.StackTrace]));
                      end;
                    end;

                  end;

                  // Ͷ����һ��WSARecv
                  if not SockObj.WSARecv() then
                  begin
                    // �������
                    OutputDebugStr(Format('WSARecv��������socket=%d:%d',
                      [SockObj.FSock, WSAGetLastError]));

                    // ��������
                    SockMgr := SockObj.FSockMgr;
                    SockMgr.DecSockBaseRef(SockObj);
                  end;
                end;
              otSend:
                begin
                  // ��ȡ�¼�ָ��
                  // ����ָ�����
                  Inc(PByte(FIocpOverlapped.CurSendData), BytesTransferred);
                  // �����ȫ��������ɣ��ͷ��ڴ�
                  if UIntPtr(FIocpOverlapped.CurSendData) -
                    UIntPtr(FIocpOverlapped.SendData) = FIocpOverlapped.SendDataLen then
                  begin
                    // �����¼�
                    if _IOCPObj <> nil then
                    begin
                      try
                        _IOCPObj.OnIOCPEvent(ieSendAll, SockObj, FIocpOverlapped);
                      except
                        on E: Exception do
                        begin
                          OutputDebugStr(Format('Message=%s, StackTrace=%s',
                            [E.Message, E.StackTrace]));
                        end;
                      end;
                    end;
                    SockMgr := SockObj.FSockMgr;
                    SockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);

                    // ��ȡ�����͵�����

                    FIocpOverlapped := nil;

                    SockMgr.Lock;
                    Assert(SockObj.FIsSending);
                    if SockObj.FSendDataQueue.Count > 0 then
                    begin
                      FIocpOverlapped := SockObj.FSendDataQueue.Items[0];
                      SockObj.FSendDataQueue.Delete(0);
                      OutputDebugStr(Format('Socket(%d)ȡ������������', [SockObj.FSock]));
                    end
                    else
                    begin
                      SockObj.FIsSending := False;
                    end;
                    SockMgr.Unlock;

                    // Ĭ�ϼ���Socket����
                    _NeedDecSockObj := True;
                    if FIocpOverlapped <> nil then
                    begin
                      if not SockObj.WSASend(FIocpOverlapped) then
                      // Ͷ��WSASend
                      begin
                        // ����д���
                        OutputDebugStr(Format('IocpWorkThread:WSASend����ʧ��(socket=%d):%d',
                          [SockObj.FSock, WSAGetLastError]));
                        if _IOCPObj <> nil then
                        begin
                          try
                            _IOCPObj.OnIOCPEvent(ieSendFailed, SockObj, FIocpOverlapped);
                          except
                            on E: Exception do
                            begin
                              OutputDebugStr(Format('Message=%s, StackTrace=%s',
                                [E.Message, E.StackTrace]));
                            end;
                          end;
                        end;

                        SockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);
                      end
                      else
                      begin
                        // ���ͳɹ�������������
                        _NeedDecSockObj := False;
                      end;
                    end;

                    if _NeedDecSockObj then
                    begin
                      // ��������
                      SockMgr.DecSockBaseRef(SockObj);
                    end;
                  end
                  else
                  begin
                    // û��ȫ���������
                    FIocpOverlapped.DataBuf.len := FIocpOverlapped.SendDataLen +
                      UIntPtr(FIocpOverlapped.SendData) -
                      UIntPtr(FIocpOverlapped.CurSendData);
                    FIocpOverlapped.DataBuf.buf := FIocpOverlapped.CurSendData;

                    if _IOCPObj <> nil then
                    begin
                      try
                        _IOCPObj.OnIOCPEvent(ieSendPart, SockObj, FIocpOverlapped);
                      except
                        on E: Exception do
                        begin
                          OutputDebugStr(Format('Message=%s, StackTrace=%s',
                            [E.Message, E.StackTrace]));
                        end;
                      end;
                    end;
                    // ����Ͷ��WSASend
                    if not SockObj.WSASend(FIocpOverlapped) then
                    begin // �������
                      OutputDebugStr(Format('WSASend��������socket=%d:%d',
                        [SockObj.FSock, WSAGetLastError]));

                      if _IOCPObj <> nil then
                      begin
                        try
                          _IOCPObj.OnIOCPEvent(ieSendFailed, SockObj, FIocpOverlapped);
                        except
                          on E: Exception do
                          begin
                            OutputDebugStr(Format('Message=%s, StackTrace=%s',
                              [E.Message, E.StackTrace]));
                          end;
                        end;
                      end;
                      SockObj.FSockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);
                      // ��������
                      SockMgr := SockObj.FSockMgr;
                      SockMgr.DecSockBaseRef(SockObj);
                    end;
                  end;
                end;
            end;
            if _IOCPObj <> nil then
            begin
              TSocketMgr.DecIOCPObjRef(_IOCPObj);
            end;
          end;
        otListen:
          begin
            Assert(FIocpOverlapped = SockLst.FAssignedOverlapped,
              'FIocpOverlapped != SockLst.FLstOverLap');
            GetAcceptExSockaddrs(SockLst.FLstBuf, 0, SizeOf(SOCKADDR_IN) + 16,
              SizeOf(SOCKADDR_IN) + 16, local, localLen, remote, remoteLen);

            // ����������
            resuInt := setsockopt(FIocpOverlapped.AcceptSocket, SOL_SOCKET,
              SO_UPDATE_ACCEPT_CONTEXT, @SockLst.FSock, SizeOf(SockLst.FSock));
            if resuInt <> 0 then
            begin
              OutputDebugStr(Format('socket(%d)����setsockoptʧ��:%d',
                [FIocpOverlapped.AcceptSocket, WSAGetLastError()]));
            end;
            // ��ȡIOCPObj�����û��
            _IOCPObj := SockBase.FSockMgr.IncIOCPObjRef;
            // ����
            if _IOCPObj <> nil then
            begin

              // �����¼������SockObj�����ʧ�ܣ���close֮
              _NewSockObj := nil;
              // �����µ�SocketObj��
              SockLst.CreateSockObj(_NewSockObj);
              // ���Socket���
              _NewSockObj.FSock := FIocpOverlapped.AcceptSocket;
              // ����Ϊ����socket
              _NewSockObj.FIsSerSocket := True;
              // ��ӵ�Socket�б���
              if _IOCPObj.AddSockObj(_NewSockObj) then
              begin

              end
              else
              begin
                closesocket(FIocpOverlapped.AcceptSocket);
              end;
              // Ͷ����һ��Accept�˿�
              if not SockLst.Accept() then
              begin
                OutputDebugStr('AcceptEx����ʧ��: ' + IntToStr(WSAGetLastError));
                SockMgr := SockLst.FSockMgr;
                SockMgr.FreeSockLst(SockLst);
              end;
              TSocketMgr.DecIOCPObjRef(_IOCPObj);
            end
            else
            begin
              // IOCPBase���Ѿ��ͷ�
              OutputDebugStr('IOCPBase���Ѿ��ͷš����Socketʧ��');
              closesocket(FIocpOverlapped.AcceptSocket);
            end;
          end;
      end;
    end
    else
    begin
      if FIocpOverlapped <> nil then
      begin
        OutputDebugStr(Format('GetQueuedCompletionStatus����ʧ��(socket=%d): %d',
          [SockBase.FSock, GetLastError]));
        // �ر�
        if FIocpOverlapped <> SockBase.FAssignedOverlapped then
        begin
          // ֻ��otSend��FIocpOverlapped
          Assert(FIocpOverlapped.OverlappedType = otSend);
          SockBase.FSockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);
        end;
        // ��������
        SockMgr := SockBase.FSockMgr;
        case FIocpOverlapped.OverlappedType of
          otRecv, otSend:
            begin
              SockMgr.DecSockBaseRef(SockObj);
            end;
          otListen:
            begin
              SockMgr.FreeSockLst(SockLst);
            end;
        end;
      end
      else
      begin
        OutputDebugStr(Format('GetQueuedCompletionStatus����ʧ��: %d', [GetLastError]));

      end;

    end;
  end;
  Result := 0;
end;

{ TSocketLst }

function TSocketLst.Accept: Boolean;
var
  BytesReceived: DWORD;
begin
  Assert(FAssignedOverlapped <> nil);
  Assert(FAssignedOverlapped.OverlappedType = otListen);
  // ���Overlapped
  ZeroMemory(@FAssignedOverlapped.lpOverlapped, SizeOf(FAssignedOverlapped.lpOverlapped));

  FAssignedOverlapped.AcceptSocket := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0,
    WSA_FLAG_OVERLAPPED);

  Result := (AcceptEx(FSock, FAssignedOverlapped.AcceptSocket, FLstBuf, 0,
    SizeOf(sockaddr_storage) + 16, SizeOf(sockaddr_storage) + 16, BytesReceived,
    @FAssignedOverlapped.lpOverlapped) = True) or (WSAGetLastError = WSA_IO_PENDING);
  // Ͷ��AcceptEx
  if not Result then
  begin
    closesocket(FAssignedOverlapped.AcceptSocket);
    FAssignedOverlapped.AcceptSocket := INVALID_SOCKET;
  end;
end;

constructor TSocketLst.Create;
begin
  inherited;
  FSocketPoolSize := 10;
end;

procedure TSocketLst.CreateSockObj(var SockObj: TSocketObj);
begin
  Assert(SockObj = nil);
  SockObj := TSocketObj.Create;
end;

destructor TSocketLst.Destroy;
begin

  if FLstBuf <> nil then
  begin
    FreeMem(FLstBuf);
  end;

  inherited;
end;

function TSocketLst.Init: Boolean;
begin

  GetMem(FLstBuf, FLstBufLen); // ����������ݵ��ڴ�
  Result := True;
end;

procedure TSocketLst.SetSocketPoolSize(const Value: Integer);
begin
  if not FIsInited then
  begin
    if Value > 0 then
    begin
      FSocketPoolSize := Value;
    end;
  end
  else
  begin
    raise Exception.Create('SocketPoolSize can''t be set after StartListen');
  end;
end;

function TSocketLst.StartListen(IOCPList: TIOCPBaseList; Port: Integer;
  InAddr: u_long): Boolean;
var
  InternetAddr: TSockAddrIn;
  // ListenSock: Integer;
  ErrorCode: Integer;
begin
  Result := False;
  FPort := Port;
  FSock := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, WSA_FLAG_OVERLAPPED);
  if (FSock = INVALID_SOCKET) then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('WSASocket ����ʧ�ܣ�' + IntToStr(ErrorCode));
    Exit;
  end;
  InternetAddr.sin_family := AF_INET;
  InternetAddr.sin_addr.s_addr := htonl(InAddr);
  InternetAddr.sin_port := htons(Port);
  // �󶨶˿ں�
  if (bind(FSock, @InternetAddr, SizeOf(InternetAddr)) = SOCKET_ERROR) then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('bind ����ʧ�ܣ�' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
    Exit;
  end;
  // ��ʼ����
  if listen(FSock, SOMAXCONN) = SOCKET_ERROR then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('listen ����ʧ�ܣ�' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
    Exit;
  end;
  // ��ӵ�SockLst
  Result := IOCPList.AddSockLst(Self);
  if not Result then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('AddSockLst ����ʧ�ܣ�' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
  end;
end;

{ TSocketObj }

function TSocketObj.ConnectSer(IOCPList: TIOCPBaseList; const SerAddr: string;
  Port: Integer): Boolean;
var
  LastError: DWORD;
  _Hints: TAddrInfoA;
  _ResultAddInfo: PADDRINFOA;
  _NextAddInfo: PADDRINFOA;
  _Retval: Integer;
{$IFDEF DEBUG}
  _DebugStr: string;
{$ENDIF}
  _AddrString: string;
  _AddrStringLen: DWORD;
begin
  Assert(FIsSerSocket = False, '');
  Result := False;
  ZeroMemory(@_Hints, SizeOf(_Hints));
  _Hints.ai_family := AF_UNSPEC;
  _Hints.ai_socktype := SOCK_STREAM;
  _Hints.ai_protocol := IPPROTO_TCP;

  _Retval := getaddrinfo(PAnsiChar(AnsiString(SerAddr)),
    PAnsiChar(AnsiString(IntToStr(Port))), @_Hints, _ResultAddInfo);
  if _Retval <> 0 then
  begin
    Exit;
  end;
  _NextAddInfo := _ResultAddInfo;

  while _NextAddInfo <> nil do
  begin
    _AddrStringLen := 1024;
    // ���뻺����
    SetLength(_AddrString, _AddrStringLen);
    // ��ȡ
{$IFDEF DEBUG}
    if WSAAddressToString(_NextAddInfo.ai_addr, _NextAddInfo.ai_addrlen, nil,
      PChar(_AddrString), _AddrStringLen) = 0 then
    begin
      // ��Ϊ��ʵ����,�����_AddrStringLen������ĩβ���ַ�#0������Ҫ��ȥ���#0�ĳ���
      SetLength(_AddrString, _AddrStringLen - 1);

      _DebugStr := Format('ai_addr:%s,ai_flags:%d,ai_canonname=%s',
        [_AddrString, _NextAddInfo.ai_flags, _NextAddInfo.AI_CANONNAME]);
      OutputDebugStr(_DebugStr);

    end
    else
    begin
      _AddrString := 'None';
      OutputDebugStr('WSAAddressToString Error');
    end;
{$ENDIF}
    FSock := WSASocket(_NextAddInfo.ai_family, _NextAddInfo.ai_socktype,
      _NextAddInfo.ai_protocol, nil, 0, WSA_FLAG_OVERLAPPED);

    if FSock <> INVALID_SOCKET then
    begin
      if connect(FSock, _NextAddInfo.ai_addr, _NextAddInfo.ai_addrlen) = SOCKET_ERROR then
      begin
        LastError := WSAGetLastError();
{$IFDEF DEBUG}
        OutputDebugStr(Format('����%sʧ�ܣ�%d', [_AddrString, LastError]));
{$ENDIF}
        closesocket(FSock);
        WSASetLastError(LastError);
        FSock := INVALID_SOCKET;
      end
      else
      begin
        Result := IOCPList.AddSockObj(Self);
        Break;
      end;
    end;
    _NextAddInfo := _NextAddInfo.ai_next;

  end;
  freeaddrinfo(_ResultAddInfo);

end;

constructor TSocketObj.Create;
begin
  inherited;
  // ���ó�ʼ������Ϊ4096
  FRecvBufLen := 4096;
end;

destructor TSocketObj.Destroy;
var
  _TmpData: Pointer;
  _IOCPOverlapped: PIOCPOverlapped absolute _TmpData;
begin
  if FSendDataQueue <> nil then
  begin
    for _TmpData in FSendDataQueue do
    begin
      FSockMgr.FIOCPMgr.DelOverlapped(_IOCPOverlapped);
    end;
    FSendDataQueue.Free;
  end;
  if FRecvBuf <> nil then
  begin
    FreeMem(FRecvBuf);
  end;
  inherited;
end;

procedure TSocketObj.FreeSendData(Data: Pointer);
begin
  FreeMem(Data);
end;

function TSocketObj.GetRecvBuf: Pointer;
begin
  Result := FRecvBuf;
end;

function TSocketObj.GetRemoteIP: string;
var
  name: TSockAddr;
  namelen: Integer;
begin
  namelen := SizeOf(name);
  if getpeername(FSock, name, namelen) = 0 then
  begin
    Result := string(inet_ntoa(name.sin_addr));
  end
  else
  begin
    // OutputDebugStr(Format('socket(%d)getpeernameʧ��:%d', [FSock, WSAGetLastError()]));
    Result := '';
  end;
end;

function TSocketObj.GetRemotePort: Word;
var
  name: TSockAddr;
  namelen: Integer;
begin
  namelen := SizeOf(name);
  if getpeername(FSock, name, namelen) = 0 then
  begin
    Result := ntohs(name.sin_port);
  end
  else
  begin
    // OutputDebugStr(Format('socket(%d)getpeernameʧ��:%d', [FSock, WSAGetLastError()]));
    Result := 0;
  end;
end;

function TSocketObj.GetSendData(DataLen: LongWord): Pointer;
begin
  GetMem(Result, DataLen);
end;

function TSocketObj.Init: Boolean;
begin
  Assert(FRecvBufLen > 0);
  Result := False;
  GetMem(FRecvBuf, FRecvBufLen); // ����������ݵ��ڴ�
  if FRecvBuf = nil then
  begin
    Exit;
  end;
  // ��ʼ��
  FSendDataQueue := TList.Create;
  Result := True;
end;

function TSocketObj.SendData(Data: Pointer; DataLen: LongWord;
  UseGetSendDataFunc: Boolean): Boolean;
var
  FIocpOverlapped: PIOCPOverlapped;
  _NewData: Pointer;
  _IsSending: Boolean;
  _IsInited: Boolean;
begin
  if DataLen = 0 then
  begin
    Result := True;
    Exit;
  end;
  // ����������
  FSockMgr.IncSockBaseRef(Self);
  _NewData := nil;
  Assert(Data <> nil);
  Result := False;

  FIocpOverlapped := FSockMgr.FIOCPMgr.NewOverlapped(Self, otSend);
  if FIocpOverlapped <> nil then
  begin

    if UseGetSendDataFunc then
    begin
      // ��䷢�������йص���Ϣ
      FIocpOverlapped.SendData := Data;
    end
    else
    begin
      GetMem(_NewData, DataLen);
      CopyMemory(_NewData, Data, DataLen);
      FIocpOverlapped.SendData := _NewData;
    end;
    FIocpOverlapped.CurSendData := FIocpOverlapped.SendData;
    FIocpOverlapped.SendDataLen := DataLen;

    FIocpOverlapped.DataBuf.buf := FIocpOverlapped.CurSendData;
    FIocpOverlapped.DataBuf.len := FIocpOverlapped.SendDataLen;
    FSockMgr.Lock;
    _IsSending := FIsSending;
    _IsInited := FIsInited;
    // ������������ڷ��͵�
    if FIsSending then
    begin
      FSendDataQueue.Add(FIocpOverlapped);
      OutputDebugStr(Format('Socket(%d)�еķ������ݼ��뵽�����Ͷ���', [Self.FSock]));
    end
    else
    begin
      FIsSending := True;
    end;
    FSockMgr.Unlock;

    if not _IsSending then
    begin
      // OutputDebugStr(Format('SendData:Overlapped=%p,Overlapped=%d',[FIocpOverlapped, Integer(FIocpOverlapped.OverlappedType)]));

      if not Self.WSASend(FIocpOverlapped) then // Ͷ��WSASend
      begin
        // ����д���
        OutputDebugStr(Format('SendData:WSASend����ʧ��(socket=%d):%d',
          [FSock, WSAGetLastError]));
        // ɾ����Overlapped
        FSockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);

        FSockMgr.Lock;
        FIsSending := False;
        FSockMgr.Unlock;
      end
      else
      begin
        Result := True;
      end;
    end
    else
    begin
      // ��ӵ������Ͷ��е����ݲ����������ã������Ҫȡ����ǰ��Ԥ����
      FSockMgr.DecSockBaseRef(Self);
      Result := True;
    end;
  end;

  if not Result then
  begin
    if not UseGetSendDataFunc then
    begin
      if _NewData <> nil then
      begin
        FreeMem(_NewData);
      end;
    end;
    // ��������
    FSockMgr.DecSockBaseRef(Self);
  end;
end;

procedure TSocketObj.SetKeepAlive(IsOn: Boolean;
  KeepAliveTime, KeepAliveInterval: Integer);
var
  alive_in: tcp_keepalive;
  alive_out: tcp_keepalive;
  ulBytesReturn: ulong;
begin
  alive_in.KeepAliveTime := KeepAliveTime; // ��ʼ�״�KeepAlive̽��ǰ��TCP�ձ�ʱ��
  alive_in.KeepAliveInterval := KeepAliveInterval; // ����KeepAlive̽����ʱ����
  alive_in.onoff := u_long(IsOn);
  WSAIoctl(FSock, SIO_KEEPALIVE_VALS, @alive_in, SizeOf(alive_in), @alive_out,
    SizeOf(alive_out), @ulBytesReturn, nil, nil);
end;

procedure TSocketObj.SetRecvBufLenBeforeInit(NewRecvBufLen: DWORD);
begin
  if FRecvBufLen <> NewRecvBufLen then
  begin
    FRecvBufLen := NewRecvBufLen;
  end;
end;

function TSocketObj.WSARecv(): Boolean;
var
  Flags: DWORD;
begin
  // ���Overlapped
  ZeroMemory(@FAssignedOverlapped.lpOverlapped, SizeOf(FAssignedOverlapped.lpOverlapped));
  // ����OverLap
  FAssignedOverlapped.DataBuf.len := FRecvBufLen;
  FAssignedOverlapped.DataBuf.buf := FRecvBuf;
  Flags := 0;
  Result := (LCXLWinSock2.WSARecv(FSock, @FAssignedOverlapped.DataBuf, 1, nil, @Flags,
    @FAssignedOverlapped.lpOverlapped, nil) = 0) or (WSAGetLastError = WSA_IO_PENDING)
end;

function TSocketObj.WSASend(Overlapped: PIOCPOverlapped): Boolean;
begin
  // OutputDebugStr(Format('WSASend:Overlapped=%p,Overlapped=%d',[Overlapped, Integer(Overlapped.OverlappedType)]));
  // ���Overlapped
  ZeroMemory(@Overlapped.lpOverlapped, SizeOf(Overlapped.lpOverlapped));

  Assert(Overlapped.OverlappedType = otSend);
  Assert((Overlapped.DataBuf.buf <> nil) and (Overlapped.DataBuf.len > 0));

  Result := (LCXLWinSock2.WSASend(FSock, @Overlapped.DataBuf, 1, nil, 0,
    @Overlapped.lpOverlapped, nil) = 0) or (WSAGetLastError = WSA_IO_PENDING)
end;

{ TSocketMgrObj }

function TSocketMgr.AddSockLst(SockLst: TSocketLst): Boolean;
begin
  Result := IOCPRegSockBase(SockLst);
  if Result then
  begin
    Lock;
    Result := FSockLstList.Add(SockLst) >= 0;
    Unlock;
  end;
end;

function TSocketMgr.IOCPRegSockBase(SockBase: TSocketBase): Boolean;
begin
  Assert(FIOCPList <> nil);
  // ��IOCP��ע���Socket
  SockBase.FIOComp := CreateIoCompletionPort(SockBase.FSock, FIOCPMgr.FCompletionPort,
    ULONG_PTR(SockBase), 0);
  Result := SockBase.FIOComp <> 0;
  if not Result then
  begin
    OutputDebugStr(Format('Socket(%d)IOCPע��ʧ�ܣ�Error:%d',
      [SockBase.FSock, WSAGetLastError()]));
  end;
end;

function TSocketMgr.IsCanFree: Boolean;
begin
  Result := (FIOCPList = nil) and (FSockObjList.Count = 0) and (FSockLstList.Count = 0)
    and (FSockObjDelList.Count = 0) and (FSockObjAddList.Count = 0);
end;

function TSocketMgr.AddSockObj(SockObj: TSocketObj): Boolean;
var
  _IsLocked: Boolean;
begin
  Assert(SockObj.FSock <> INVALID_SOCKET);
  SockObj.FSockMgr := Self;
  Lock;
  // List�Ƿ���ס
  _IsLocked := FLockRefNum > 0;
  if _IsLocked then
  begin
    // ����ס�����ܶ�Socket�б������ӻ�ɾ���������ȼӵ�Socket�����List�С�
    FSockObjAddList.Add(SockObj);
    OutputDebugStr(Format('�б�������Socket(%d)�������Ӷ���', [SockObj.FSock]));
  end
  else
  begin
    // û�б���ס��ֱ����ӵ�Socket�б���
    FSockObjList.Add(SockObj);

  end;
  Unlock;
  if not _IsLocked then
  begin
    // ���û�б���ס����ʼ��Socket
    // ����SockObj�����ã������ʼ��ʧ�ܵ�ʱ��ᱻ�Զ�Free��
    IncSockBaseRef(SockObj);
    Result := InitSockObj(SockObj);
    if Result then
    begin
      // ��ʼ���ɹ��ˣ��Ǿͼ���SockObj������
      DecSockBaseRef(SockObj);
    end
    else
    begin
      // ��ʼ������
      Assert(SockObj.FRefCount = 1);

    end;
  end
  else
  begin
    // �������ס���Ƿ���ֵ��Զ��True
    Result := True;
  end;
end;

constructor TSocketMgr.Create(AIOCPMgr: TIOCPManager);
begin
  inherited Create();
  FLockRefNum := 0;
  FIOCPMgr := AIOCPMgr;
  InitializeCriticalSection(FSockObjCS);
  FSockObjList := TList.Create;
  FSockObjAddList := TList.Create;
  FSockObjDelList := TList.Create;

  FSockLstList := TList.Create;
  FSockLstAddList := TList.Create;
  FSockLstDelList := TList.Create;
end;

class procedure TSocketMgr.DecIOCPObjRef(IOCPObj: TIOCPBaseList);
var
  _IOCPObj: TIOCPBaseList;
  CanFree: Boolean;
  SockMgr: TSocketMgr;
  IOCPMgr: TIOCPManager;
begin
  _IOCPObj := nil;
  SockMgr := IOCPObj.FSockMgr;
  // ����
  SockMgr.Lock;
  Assert(SockMgr.FIOCPList <> nil);
  // ��������
  Dec(SockMgr.FIOCPList.FRefCount);

  if SockMgr.FIOCPList.FRefCount = 0 then
  begin
    Assert(SockMgr.FIOCPList.FIsFreeing);

    _IOCPObj := SockMgr.FIOCPList;
    SockMgr.FIOCPList := nil;
  end;
  CanFree := SockMgr.IsCanFree();
  SockMgr.Unlock;
  // _IOCPObj�Ƿ�����ͷ�
  if _IOCPObj <> nil then
  begin
    // �ͷ�IOCPObj�ڴ�
    Assert(_IOCPObj.FCanDestroyEvent <> 0);
    SetEvent(_IOCPObj.FCanDestroyEvent);
    // _IOCPObj.FCanDestroy := True;
    // _IOCPObj.Destroy;
    if CanFree then
    begin
      IOCPMgr := SockMgr.FIOCPMgr;
      IOCPMgr.FreeSockMgr(SockMgr);
    end;
  end;
end;

class function TSocketMgr.DecSockBaseRef(SockBase: TSocketBase): Integer;
var
  _IsLocked: Boolean;
  SockObj: TSocketObj absolute SockBase;
  SockLst: TSocketLst absolute SockBase;
begin
  SockBase.FSockMgr.Lock;
  Dec(SockBase.FRefCount);
  Result := SockBase.FRefCount;
  SockBase.FSockMgr.Unlock;
  if Result = 0 then
  begin
    if SockBase is TSocketObj then
    begin
      SockBase.FSockMgr.Lock;

      _IsLocked := SockBase.FSockMgr.FLockRefNum > 0;
      if _IsLocked then
      begin
        OutputDebugStr(Format('�б�������Socket(%d)�����ɾ������', [SockBase.FSock]));
        SockBase.FSockMgr.FSockObjDelList.Add(SockObj);
      end
      else
      begin
        SockBase.FSockMgr.FSockObjList.Remove(SockObj);
      end;
      SockBase.FSockMgr.Unlock;
      // ���û�б�����
      if not _IsLocked then
      begin
        FreeSockObj(SockObj);
      end;
    end
    else if SockBase is TSocketLst then
    begin
      FreeSockLst(SockLst);
    end
    else
    begin
      Assert(False, 'unknown SockBase');
    end;
  end;
end;

destructor TSocketMgr.Destroy;
begin
  FSockLstDelList.Free;
  FSockLstAddList.Free;
  FSockLstList.Free;

  FSockObjDelList.Free;
  FSockObjAddList.Free;
  FSockObjList.Free;

  DeleteCriticalSection(FSockObjCS);
  inherited;
end;

class procedure TSocketMgr.FreeSockLst(SockLst: TSocketLst);
var
  CanFree: Boolean;
  _IOCPObj: TIOCPBaseList;
  SockMgr: TSocketMgr;
  IOCPMgr: TIOCPManager;
begin
  SockMgr := SockLst.FSockMgr;

  SockMgr.Lock;
  // ���б����Ƴ�
  SockMgr.FSockLstList.Remove(SockLst);
  SockMgr.Unlock;

  _IOCPObj := SockMgr.IncIOCPObjRef;
  if _IOCPObj <> nil then
  begin
    _IOCPObj.OnListenEvent(leDelSockLst, SockLst);
    TSocketMgr.DecIOCPObjRef(_IOCPObj);
  end;
  IOCPMgr := SockMgr.FIOCPMgr;
  // ɾ��OverLapped
  IOCPMgr.DelOverlapped(SockLst.FAssignedOverlapped);
  SockMgr.Lock;
  CanFree := SockMgr.IsCanFree();
  SockMgr.Unlock;

  SockLst.Free;
  if CanFree then
  begin
    IOCPMgr.FreeSockMgr(SockMgr);
  end;
end;

class procedure TSocketMgr.FreeSockObj(SockObj: TSocketObj);
var
  CanFree: Boolean;
  _IOCPObj: TIOCPBaseList;
  SockMgr: TSocketMgr;
  IOCPMgr: TIOCPManager;
begin
  SockMgr := SockObj.FSockMgr;

  // ����IOCPObj
  _IOCPObj := SockMgr.IncIOCPObjRef();
  if _IOCPObj <> nil then
  begin
    // �����¼�����ʱsocket�Ѿ����б���ɾ����
    try
      _IOCPObj.OnIOCPEvent(ieDelSocket, SockObj, nil);
    except

    end;
    TSocketMgr.DecIOCPObjRef(_IOCPObj);
  end;
  SockMgr.Lock;
  Assert(SockObj.FRefCount = 0);
  CanFree := SockMgr.IsCanFree;
  SockMgr.Unlock;
  // ɾ��
  if (SockObj.FAssignedOverlapped <> nil) then
  begin
    SockObj.FSockMgr.FIOCPMgr.DelOverlapped(SockObj.FAssignedOverlapped);
  end;
  // �ͷ�sockobj
  SockObj.Free;

  if CanFree then
  begin
    IOCPMgr := SockMgr.FIOCPMgr;
    IOCPMgr.FreeSockMgr(SockMgr);
  end;
end;

function TSocketMgr.IncIOCPObjRef: TIOCPBaseList;
begin
  Lock;
  Result := FIOCPList;
  if Result <> nil then
  begin
    if Result.FIsFreeing then
    begin
      Result := nil;
    end
    else
    begin
      Inc(Result.FRefCount);
    end;
  end;
  Unlock;
end;

function TSocketMgr.IncSockBaseRef(SockBase: TSocketBase): Integer;
begin
  Lock;
  Assert(SockBase.FRefCount > 0);
  Inc(SockBase.FRefCount);
  Result := SockBase.FRefCount;

  Unlock;

end;

function TSocketMgr.InitSockObj(SockObj: TSocketObj): Boolean;
var
  _IOCPObj: TIOCPBaseList;
begin
  Result := False;
  // ��ʼ��ʼ��Socket
  if SockObj.Init() then
  begin
    // ����
    Lock;
    SockObj.FIsInited := True;
    Unlock;
    Assert(SockObj.FRefCount > 0);
    // ��ӵ�Mgr
    if IOCPRegSockBase(SockObj) then
    begin
      // �ɹ�������IsSucΪTrue
      Result := True;
    end;
  end;
  // ����IOCPObj
  _IOCPObj := IncIOCPObjRef();

  // �Ƿ�ɹ���������ӵ�sockobj�б�
  if Result then
  begin
    if _IOCPObj <> nil then
    begin
      try
        _IOCPObj.OnIOCPEvent(ieAddSocket, SockObj, nil);
      except

      end;
    end;
    // ���Recv��Overlapped
    SockObj.FAssignedOverlapped := FIOCPMgr.NewOverlapped(SockObj, otRecv);
    if not SockObj.WSARecv() then // Ͷ��WSARecv
    begin // �������
      OutputDebugStr(Format('InitSockObj:WSARecv��������socket=%d:%d',
        [SockObj.FSock, WSAGetLastError]));

      if _IOCPObj <> nil then
      begin
        try
          _IOCPObj.OnIOCPEvent(ieRecvFailed, SockObj, SockObj.FAssignedOverlapped);
        except

        end;
      end;
      // ��������
      DecSockBaseRef(SockObj);
      Result := False;
    end;
  end
  else
  begin
    // ��������
    DecSockBaseRef(SockObj);
  end;
  if _IOCPObj <> nil then
  begin
    TSocketMgr.DecIOCPObjRef(_IOCPObj);
  end;
end;

procedure TSocketMgr.Lock;
begin
  EnterCriticalSection(FSockObjCS);

end;

procedure TSocketMgr.LockSockList;
begin
  Lock;
  Assert(FLockRefNum >= 0);
  Inc(FLockRefNum);
  Unlock;
end;

procedure TSocketMgr.SetIOCPObjCanFree;
var
  SockBasePtr: Pointer;
  SockBase: TSocketBase absolute SockBasePtr;

  IOCPObj: TIOCPBaseList;
begin
  Lock;
  IOCPObj := FIOCPList;
  // ��ʼ�Զ��ͷ�
  FIOCPList.FIsFreeing := True;
  // �ر����еļ���
  for SockBasePtr in FSockLstList do
  begin
    SockBase.Close;
  end;
  // �ر����е�socket
  for SockBasePtr in FSockObjList do
  begin
    SockBase.Close;
  end;
  // �ر����д���ӵ�socket
  for SockBasePtr in FSockObjAddList do
  begin
    SockBase.Close;
  end;
  Unlock;
  // ��������
  // ����������
  DecIOCPObjRef(IOCPObj);
end;

procedure TSocketMgr.Unlock;
begin
  LeaveCriticalSection(FSockObjCS);
end;

procedure TSocketMgr.UnlockSockList;
var
  isAdd: Boolean;
  SockObj: TSocketObj;
  _IsEnd: Boolean;
begin
  isAdd := False;
  repeat
    SockObj := nil;
    Lock;
    Assert(FLockRefNum >= 1, 'Socket�б������߳�������');
    // �ж��ǲ���ֻ�б��߳��������б�ֻҪ�ж�FLockRefNum�ǲ��Ǵ���1
    _IsEnd := FLockRefNum > 1;
    if not _IsEnd then
    begin
      // ֻ�б��߳���ס��socket��Ȼ��鿴socketɾ���б��Ƿ�Ϊ��
      if FSockObjDelList.Count > 0 then
      begin
        // ��Ϊ�գ��ӵ�һ����ʼɾ
        SockObj := FSockObjDelList.Items[0];
        FSockObjDelList.Delete(0);
        FSockObjList.Remove(SockObj);
        isAdd := False;
      end
      else
      begin
        // �鿴socket����б��Ƿ�Ϊ��
        if FSockObjAddList.Count > 0 then
        begin
          isAdd := True;
          // �����Ϊ�գ���popһ��sockobj��ӵ��б���
          SockObj := FSockObjAddList.Items[0];
          FSockObjAddList.Delete(0);
          FSockObjList.Add(SockObj);
        end
        else
        begin
          // ��Ϊ�գ����ʾ�Ѿ�������
          _IsEnd := True;
        end;
      end;
    end;
    // ���ûʲô��Ҫ������ˣ������б�����1
    if _IsEnd then
    begin
      Dec(FLockRefNum);
    end;
    Unlock;

    // �鿴sockobj�Ƿ�Ϊ�գ���Ϊ�����ʾ����List�ڼ���ɾ��sock�������sock����
    if SockObj <> nil then
    begin

      if isAdd then
      begin
        // �����sock��������ʼ��sockobj�����ʧ�ܣ����Զ���Free���������ȡ����ֵ
        InitSockObj(SockObj);
      end
      else
      begin
        // ��ɾ��sock������ɾ��sockobk
        FreeSockObj(SockObj);
      end;
    end;
  until _IsEnd;
end;

{ TIOCPOBJBase }

function TIOCPBaseList.AddSockLst(NewSockLst: TSocketLst): Boolean;
var
  IsSuc: Boolean;
begin
  NewSockLst.FSockMgr := FSockMgr;
  NewSockLst.FLstBufLen := (SizeOf(sockaddr_storage) + 16) * 2;
  IsSuc := False;
  if NewSockLst.Init() then
  begin
    NewSockLst.FIsInited := True;
    // ��ӵ�Mgr
    if FSockMgr.AddSockLst(NewSockLst) then
    begin

      // �ɹ�������IsSucΪTrue
      IsSuc := True;
    end;
  end;
  if IsSuc then
  begin
    OnListenEvent(leAddSockLst, NewSockLst);
    // ���Listen��Overlapped
    NewSockLst.FAssignedOverlapped := FSockMgr.FIOCPMgr.NewOverlapped(NewSockLst,
      otListen);
    if not NewSockLst.Accept() then // Ͷ��AcceptEx
    begin
      OutputDebugStr('AcceptEx����ʧ��: ' + IntToStr(WSAGetLastError));
      NewSockLst.Close;
      Result := False;
    end
    else
    begin
      Result := True;
    end;
  end
  else
  begin
    NewSockLst.Close;
    Result := False;
  end;
end;

function TIOCPBaseList.AddSockObj(NewSockObj: TSocketObj): Boolean;
begin
  Result := FSockMgr.AddSockObj(NewSockObj);
end;

procedure TIOCPBaseList.CloseAllSockLst;
var
  SockList: TList;
  SockLst: TSocketLst;
  SockLstPtr: Pointer;
begin
  FSockMgr.Lock;
  SockList := FSockMgr.FSockLstList;
  for SockLstPtr in SockList do
  begin
    SockLst := TSocketLst(SockLstPtr);
    // �ر�����
    SockLst.Close;
  end;
  FSockMgr.Unlock;
end;

procedure TIOCPBaseList.CloseAllSockObj;
var
  SockList: TList;
  SockObj: TSocketObj;
  SockObjPtr: Pointer;
begin
  FSockMgr.LockSockList;
  SockList := FSockMgr.FSockObjList;
  for SockObjPtr in SockList do
  begin
    SockObj := TSocketObj(SockObjPtr);
    // �ر�����
    SockObj.Close;
  end;
  FSockMgr.UnlockSockList;
end;

constructor TIOCPBaseList.Create(AIOCPMgr: TIOCPManager);
begin
  // ����SockMgr
  FSockMgr := AIOCPMgr.CreateSockMgr(Self);
end;

destructor TIOCPBaseList.Destroy;
const
  EVENT_NUMBER = 1;
var
  _IsEnd: Boolean;
  EventArray: array [0 .. EVENT_NUMBER - 1] of THandle;
begin
  // �����ͷ����¼�
  FCanDestroyEvent := CreateEvent(nil, True, False, nil);
  // ���ô�����Ա��ͷ�
  FSockMgr.SetIOCPObjCanFree;

  EventArray[0] := FCanDestroyEvent;
  _IsEnd := False;
  // �ȴ��ͷ�����¼�
  while not _IsEnd do
  begin
    case MsgWaitForMultipleObjects(1, EventArray[0], True, INFINITE, QS_ALLINPUT) of
      WAIT_OBJECT_0:
        begin
          // �����ͷ���
          _IsEnd := True;
        end;
      WAIT_OBJECT_0 + EVENT_NUMBER:
        begin
          // ��GUI��Ϣ���ȴ���GUI��Ϣ
          OutputDebugStr('TIOCPBaseList.Destroy:Process GUI Event');
          ProcessMsgEvent();
        end;
    else
      _IsEnd := True;
    end;
  end;
  inherited;
end;

class procedure TIOCPBaseList.GetLocalAddrs(Addrs: TStrings);
var
  phe: PHostEnt;
  pptr: PInAddr;
  sHostName: AnsiString;
  addrlist: PPAnsiChar;
begin
  Addrs.Clear;
  SetLength(sHostName, MAX_PATH);
  if gethostname(PAnsiChar(sHostName), MAX_PATH) = SOCKET_ERROR then
    Exit;
  phe := GetHostByName(PAnsiChar(sHostName));
  if phe = nil then
    Exit;
  addrlist := PPAnsiChar(phe^.h_addr_list);
  while addrlist^ <> nil do
  begin
    pptr := PInAddr(addrlist^);
    Addrs.Add(string(inet_ntoa(pptr^)));
    Inc(addrlist);
  end;
end;

function TIOCPBaseList.GetSockList: TList;
begin
  Result := FSockMgr.FSockObjList;
end;

function TIOCPBaseList.GetSockLstList: TList;
begin
  Result := FSockMgr.FSockLstList;
end;

procedure TIOCPBaseList.LockSockList;
begin
  FSockMgr.LockSockList;
end;

procedure TIOCPBaseList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
begin
  // �����κ����룬�븲�Ǵ��¼�
end;

procedure TIOCPBaseList.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin
  // �����κ����룬�븲�Ǵ��¼�
end;

procedure TIOCPBaseList.ProcessMsgEvent;
var
  Unicode: Boolean;
  MsgExists: Boolean;
  Msg: TMsg;
begin
  while PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE) do
  begin
    Unicode := (Msg.hwnd = 0) or IsWindowUnicode(Msg.hwnd);
    if Unicode then
      MsgExists := PeekMessageW(Msg, 0, 0, 0, PM_REMOVE)
    else
      MsgExists := PeekMessageA(Msg, 0, 0, 0, PM_REMOVE);

    if MsgExists then
    begin
      TranslateMessage(Msg);
      if Unicode then
        DispatchMessageW(Msg)
      else
        DispatchMessageA(Msg);
    end;
  end;
end;

procedure TIOCPBaseList.UnlockSockList;
begin
  FSockMgr.UnlockSockList;
end;

{ TIOCPManager }

constructor TIOCPManager.Create(IOCPThreadCount: Integer);
var
  ThreadID: DWORD;
  I: Integer;
  TmpSock: TSocket;
  dwBytes: DWORD;
begin
  inherited Create();
  IsMultiThread := True;
  OutputDebugStr('TIOCPManager.Create');
  // ʹ�� 2.2���WS2_32.DLL
  if WSAStartup($0202, FwsaData) <> 0 then
  begin
    raise Exception.Create('WSAStartup Fails');
  end;
  // ��ȡAcceptEx��GetAcceptExSockaddrs�ĺ���ָ��
  TmpSock := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, WSA_FLAG_OVERLAPPED);
  if TmpSock = INVALID_SOCKET then
  begin
    raise Exception.Create('WSASocket Fails');
  end;
  if (SOCKET_ERROR = WSAIoctl(TmpSock, SIO_GET_EXTENSION_FUNCTION_POINTER,
    @WSAID_ACCEPTEX, SizeOf(WSAID_ACCEPTEX), @@AcceptEx, SizeOf(@AcceptEx), @dwBytes, nil,
    nil)) then
  begin
    raise Exception.Create(Format('WSAIoctl WSAID_ACCEPTEX Fails:%d',
      [WSAGetLastError()]));
  end;

  if (SOCKET_ERROR = WSAIoctl(TmpSock, SIO_GET_EXTENSION_FUNCTION_POINTER,
    @WSAID_GETACCEPTEXSOCKADDRS, SizeOf(WSAID_GETACCEPTEXSOCKADDRS),
    @@GetAcceptExSockaddrs, SizeOf(@GetAcceptExSockaddrs), @dwBytes, nil, nil)) then
  begin
    raise Exception.Create(Format('WSAIoctl WSAID_GETACCEPTEXSOCKADDRS Fails:%d',
      [WSAGetLastError()]));
  end;

  closesocket(TmpSock);
  // ��ʼ���ٽ���
  InitializeCriticalSection(FSockMgrCS);
  FSockMgrList := TList.Create;

  InitializeCriticalSection(FOverLappedCS);
  FOverLappedList := TList.Create;
  // ��ʼ��IOCP��ɶ˿�
  FCompletionPort := CreateIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 0);
  if IOCPThreadCount <= 0 then
  begin
    IOCPThreadCount := CPUCount + 2;
  end;
  SetLength(FIocpWorkThreads, IOCPThreadCount);
  // ����IOCP�����߳�
  for I := 0 to IOCPThreadCount - 1 do
  begin
    FIocpWorkThreads[I] := CreateThread(nil, 0, @IocpWorkThread, Pointer(FCompletionPort),
      0, ThreadID);
    if FIocpWorkThreads[I] = 0 then
    begin
      raise Exception.Create('CreateThread FIocpWorkThreads Fails');
    end;
  end;
end;

function TIOCPManager.CreateSockMgr(IOCPBase: TIOCPBaseList): TSocketMgr;
var
  _SockMgr: TSocketMgr;
begin
  _SockMgr := TSocketMgr.Create(Self);
  _SockMgr.FIOCPList := IOCPBase;
  // ���ü�1
  _SockMgr.FIOCPList.FRefCount := 1;
  LockSockMgr;
  FSockMgrList.Add(Pointer(_SockMgr));
  UnlockSockMgr;
  Result := _SockMgr;
end;

procedure TIOCPManager.DelOverlapped(UsedOverlapped: PIOCPOverlapped);
begin
  Assert(UsedOverlapped <> nil);
  // ����ʹ������ΪFalse
  Assert(UsedOverlapped.IsUsed = True);
  (*
    OutputDebugStr(Format('DelOverlapped=%p, type=%d, socket=%d',
    [UsedOverlapped, Integer(UsedOverlapped.OverlappedType),
    UsedOverlapped.AssignedSockObj.FSock]));
  *)
  case UsedOverlapped.OverlappedType of
    otSend:
      begin
        Assert(UsedOverlapped.SendData <> nil);
        if UsedOverlapped.SendData <> nil then
        begin
          FreeMem(UsedOverlapped.SendData);
          UsedOverlapped.SendData := nil;
        end;
      end;
    otListen:
      begin
        if UsedOverlapped.AcceptSocket <> INVALID_SOCKET then
        begin
          closesocket(UsedOverlapped.AcceptSocket);
        end;
      end;
  end;

  LockOverLappedList;
  // ����ʹ������ΪFalse
  UsedOverlapped.IsUsed := False;
  FOverLappedList.Add(UsedOverlapped);
  UnlockOverLappedList;
end;

procedure TIOCPManager.FreeOverLappedList;
var
  POverL: PIOCPOverlapped;
begin
  LockOverLappedList;
  for POverL in FOverLappedList do
  begin
    Assert(POverL.IsUsed = False, 'POverL.IsUsed must be False');
    FreeMem(POverL);
  end;
  FOverLappedList.Clear;
  FOverLappedList.Free;
  FOverLappedList := nil;
  UnlockOverLappedList;
end;

destructor TIOCPManager.Destroy;
var
  Resu: Boolean;
{$IFDEF DEBUG}
  SockMgrPtr: Pointer;
  _SockMgr: TSocketMgr absolute SockMgrPtr;
{$ENDIF}
begin

  // �ر����е�Socket
  // ����
{$IFDEF DEBUG}
  LockSockMgr;
  for SockMgrPtr in FSockMgrList do
  begin
    Assert((_SockMgr.FIOCPList = nil) or (_SockMgr.FIOCPList.FIsFreeing),
      'TIOCPManager���ͷ�֮ǰ�����Ȱ�����TIOCPOBJBase���������ͷŵ���');
  end;
  UnlockSockMgr;
{$ENDIF}
  Resu := PostExitStatus();

  Assert(Resu = True);
  OutputDebugStr('�ȴ���ɶ˿ڹ����߳��˳���');
  // �ȴ������߳��˳�
  WaitForMultipleObjects(Length(FIocpWorkThreads), @FIocpWorkThreads[0], True, INFINITE);
  OutputDebugStr('�ȴ���ɶ˿ھ����');
  // �ر�IOCP���
  CloseHandle(FCompletionPort);
  // �ȴ�SockLst�ͷţ�����Ƚ�����
  // WaitSockLstFree;
  // �ͷ�
  FreeOverLappedList;
  DeleteCriticalSection(FOverLappedCS);

  Assert(FSockMgrList.Count = 0,
    'FSockMgrList.Count <> 0, you must free ALL TIOCPOBJBase class before free this class.');
  FSockMgrList.Free;
  FSockMgrList := nil;
  DeleteCriticalSection(FSockMgrCS);
  // �ر�Socket
  WSACleanup;
  inherited;
end;

procedure TIOCPManager.FreeSockMgr(SockMgr: TSocketMgr);
begin
  LockSockMgr;
  FSockMgrList.Remove(SockMgr);
  UnlockSockMgr;
  SockMgr.Free;
end;

function TIOCPManager.GetOverLappedList: TList;
begin
  Result := FOverLappedList;
end;

function TIOCPManager.GetSockMgrList: TList;
begin
  Result := FSockMgrList;
end;

procedure TIOCPManager.LockOverLappedList;
begin
  EnterCriticalSection(FOverLappedCS);
end;

procedure TIOCPManager.LockSockMgr;
begin
  EnterCriticalSection(FSockMgrCS);
end;

function TIOCPManager.NewOverlapped(SockObj: TSocketBase;
  OverlappedType: TOverlappedTypeEnum): PIOCPOverlapped;
var
  _NewOverLapped: PIOCPOverlapped;
begin

  LockOverLappedList;
  if FOverLappedList.Count > 0 then
  begin
    _NewOverLapped := FOverLappedList.Items[0];
    FOverLappedList.Delete(0);
  end
  else
  begin
    // �����ڴ�
    GetMem(_NewOverLapped, SizeOf(TIOCPOverlapped));
  end;
  _NewOverLapped.IsUsed := True;
  // �������
  UnlockOverLappedList;

  // �Ѿ�ʹ��
  _NewOverLapped.AssignedSockObj := SockObj;
  _NewOverLapped.OverlappedType := OverlappedType;
  // ����
  case OverlappedType of
    otSend:
      begin

        _NewOverLapped.SendData := nil;
        _NewOverLapped.CurSendData := nil;
        _NewOverLapped.SendDataLen := 0;
      end;
    otRecv:
      begin
        _NewOverLapped.RecvData := nil;
        _NewOverLapped.RecvDataLen := 0;
      end;
    otListen:
      begin
        _NewOverLapped.AcceptSocket := INVALID_SOCKET;
      end;
  end;
  (*
    OutputDebugStr(Format('NewOverlapped=%p, type=%d, socket=%d',
    [_NewOverLapped, Integer(_NewOverLapped.OverlappedType),
    _NewOverLapped.AssignedSockObj.FSock]));
  *)
  Result := _NewOverLapped;
end;

function TIOCPManager.PostExitStatus: Boolean;
begin
  OutputDebugStr('�����߳��˳����');
  Result := PostQueuedCompletionStatus(FCompletionPort, 0, 0, nil);
end;

procedure TIOCPManager.UnlockOverLappedList;
begin
  LeaveCriticalSection(FOverLappedCS);
end;

procedure TIOCPManager.UnlockSockMgr;
begin
  LeaveCriticalSection(FSockMgrCS);
end;

{ _IOCPOverlapped }

function _IOCPOverlapped.GetCurSendDataLen: LongWord;
begin
  Assert(OverlappedType = otSend);
  Result := DWORD_PTR(CurSendData) - DWORD_PTR(SendData);
end;

function _IOCPOverlapped.GetRecvData: Pointer;
begin
  Assert(OverlappedType = otRecv);
  Result := RecvData;
end;

function _IOCPOverlapped.GetRecvDataLen: LongWord;
begin
  Assert(OverlappedType = otRecv);
  Result := RecvDataLen;
end;

function _IOCPOverlapped.GetSendData: Pointer;
begin
  Assert(OverlappedType = otSend);
  Result := SendData;
end;

function _IOCPOverlapped.GetTotalSendDataLen: LongWord;
begin
  Assert(OverlappedType = otSend);
  Result := SendDataLen;
end;

{ TSocketBase }

procedure TSocketBase.Close;
begin
  shutdown(FSock, SD_BOTH);
  if closesocket(FSock) <> ERROR_SUCCESS then
  begin
    OutputDebugStr(Format('closesocket failed:%d', [WSAGetLastError]));
  end;
end;

{ TIOCPOBJBase2 }

procedure TIOCPBase2List.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
begin
  if Assigned(FIOCPEvent) then
  begin
    FIOCPEvent(EventType, SockObj, Overlapped);
  end;

end;

procedure TIOCPBase2List.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin
  if Assigned(FListenEvent) then
  begin
    FListenEvent(EventType, SockLst);
  end;

end;

constructor TSocketBase.Create;
begin
  inherited;
  FSock := INVALID_SOCKET;
  FRefCount := 1;
end;

end.
