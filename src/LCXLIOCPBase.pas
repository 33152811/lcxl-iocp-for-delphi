unit LCXLIOCPBase;
(* **************************************************************************** *)
(* ����: LCXL *)
(* E-mail: lcx87654321@163.com *)
(* ˵��: IOCP������Ԫ��������IOCP�����࣬IOCP�б����IOCP Socket�ࡣ *)
(* **************************************************************************** *)
interface

uses
  Windows, SysUtils, Classes, Types, LCXLWinSock2, LCXLMSWSock, LCXLMSTcpIP, LCXLWS2Def,
  LCXLWs2tcpip;

procedure OutputDebugStr(const DebugInfo: string; AddLinkBreak: Boolean=True); inline;

type
  // Iocp�׽����¼�����
  ///	<summary>
  ///	  Iocp�׽����¼�����
  ///	</summary>
  TIocpEventEnum = (
    ieAddSocket,

    ///	<summary>
    ///	  socket��IOCP�������Ƴ��¼�
    ///	</summary>
    ieDelSocket,

    ///	<summary>
    ///	  socket��ϵͳ�ر��¼������������¼�ʱ���û������ͷŴ�socket�����ã��Ա�iocp�����������socket�����û������ͷ�֮�󣬻ᴥ��ieD
    ///	  elSocket�¼�
    ///	</summary>
    ieCloseSocket,

    ieError,

    ///	<summary>
    ///	  ieRecvPart �ڱ���Ԫ��û��ʵ�֣���չ��
    ///	</summary>
    ieRecvPart,

    ///	<summary>
    ///	  �����ܵ�����ʱ�ᴥ�����¼�����
    ///	</summary>
    ieRecvAll,

    ///	<summary>
    ///	  ����ʧ��
    ///	</summary>
    ieRecvFailed,

    ///	<summary>
    ///	  ֻ������һ��������
    ///	</summary>
    ieSendPart,

    ///	<summary>
    ///	  �Ѿ�������ȫ������
    ///	</summary>
    ieSendAll,

    ///	<summary>
    ///	  <font style="BACKGROUND-COLOR: #ffffe0">����ʧ��</font>
    ///	</summary>
    ieSendFailed
  );
  TListenEventEnum = (leAddSockLst, leDelSockLst, leCloseSockLst, leListenFailed);
  // ******************* ǰ������ ************************
  TSocketBase = class;
  // �����߳��࣬Ҫʵ�ֲ�ͬ�Ĺ��ܣ���Ҫ�̳в�ʵ��������
  TSocketLst = class;
  // Overlap�ṹ
  PIOCPOverlapped = ^TIOCPOverlapped;
  // Socket��
  TSocketObj = class;
  // Socket�б��࣬Ҫʵ�ֲ�ͬ�Ĺ��ܣ���Ҫ�̳в�ʵ��������
  TCustomIOCPBaseList = class;
  // IOCP������
  TIOCPManager = class;
  // *****************************************************

  TOverlappedTypeEnum = (otRecv, otSend, otListen);

  /// <summary>
  /// socket���״̬
  /// </summary>
  TSocketInitStatus = (
    /// <summary>
    /// socket�����ڳ�ʼ��
    /// </summary>
    sisInitializing,

    /// <summary>
    /// socket���ʼ�����
    /// </summary>
    sisInitialized,

    /// <summary>
    /// socket����������
    /// </summary>
    sisDestroying);

  /// <summary>
  /// OverLap�ṹ
  /// </summary>
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
  /// <summary>
  /// Socket����
  /// </summary>
  TSocketType = (STObj, STLst);
  TSocketBase = class(TObject)
  protected
    FSocketType: TSocketType;
    // �������˶��ٴΣ���RefCountΪ0ʱ����free��Socket����
    // RefCount=1��ֻ�н���
    // RefCount-1Ϊ��ǰ���ڷ��͵Ĵ���
    FRefCount: Integer;
    // �û����ü���
    FUserRefCount: Integer;
    // �Ƿ��ʼ����
    FIniteStatus: TSocketInitStatus;
    // �׽���
    FSock: TSocket;
    // ��Socket������IOCPOBJBase�ṹ
    // �˴�IOCPOBJRec�ṹ��ָ����ڴ�һ������TsocketObjȫ���ر�ʱ�Ż���Ч
    FOwner: TCustomIOCPBaseList;
    // �˿ھ��
    FIOComp: THandle;
    //
    // Overlapped
    FAssignedOverlapped: PIOCPOverlapped;
    FTag: UIntPtr;
    function Init(): Boolean; virtual; abstract;
    /// <summary>
    /// �������ü���
    /// </summary>
    /// <returns>
    /// ���ص�ǰ�����ü���
    /// </returns>
    function InternalIncRefCount(Count: Integer = 1; UserMode: Boolean = False): Integer;

    /// <summary>
    /// �������ü����������ü���Ϊ0ʱ����sockbase���ͷ�
    /// </summary>
    /// <returns>
    /// ���ص�ǰ�����ü���
    /// </returns>
    function InternalDecRefCount(Count: Integer = 1; UserMode: Boolean = False): Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Close(); virtual;

    /// <summary>
    /// socket������
    /// </summary>
    property Owner: TCustomIOCPBaseList read FOwner;

    /// <summary>
    /// socket���
    /// </summary>
    property Socket: TSocket read FSock;

    /// <summary>
    /// �Ƿ��Ѿ���ʼ����
    /// </summary>
    property IniteStatus: TSocketInitStatus read FIniteStatus;

    /// <summary>
    /// ��ǩ���������û�����
    /// </summary>
    property Tag: UIntPtr read FTag write FTag;
    /// <summary>
    /// �������ü�����ͬʱ�����û����ú�ϵͳ���ü���
    /// </summary>
    /// <returns>
    /// ���ص�ǰ�����ü���
    /// </returns>
    function IncRefCount(Count: Integer = 1): Integer;

    /// <summary>
    /// �������ü����������ü���Ϊ0ʱ����socket�п��ܻᱻϵͳ�Զ��ͷţ��벻Ҫ�ٲ�����socket
    /// </summary>
    /// <returns>
    /// ���ص�ǰ�����ü���
    /// </returns>
    function DecRefCount(Count: Integer = 1): Integer;
    /// <summary>
    /// ���ü���
    /// </summary>
    property RefCount: Integer read FRefCount;
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
    /// <summary>
    /// ��������һ�����ӣ��͵��ô˷��������������ӵ�socket�࣬Ĭ�ϻὫ�������TAG���ݸ��µ�socket��
    /// </summary>
    procedure CreateSockObj(var SockObj: TSocketObj); virtual; // ����
  public
    constructor Create; override;
    // ����
    destructor Destroy; override;

    /// <summary>
    /// �����˿ں�
    /// </summary>
    property Port: Integer read FPort;
    /// <summary>
    /// Socket���ӳش�С
    /// </summary>
    property SocketPoolSize: Integer read FSocketPoolSize write SetSocketPoolSize;
    /// <summary>
    /// ����˿�ʼ����
    /// </summary>
    function StartListen(IOCPList: TCustomIOCPBaseList; Port: Integer;
      Family: Integer = AF_UNSPEC): Boolean;
  end;

  /// <summary>
  /// Socket�࣬һ�����һ���׽���
  /// </summary>
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

    /// <summary>
    /// ����ָ���������ַ��֧��IPv6
    /// </summary>
    /// <param name="IOCPList">
    /// Socket�б�
    /// </param>
    /// <param name="SerAddr">
    /// Ҫ���ӵĵ�ַ
    /// </param>
    /// <param name="Port">
    /// Ҫ���ӵĶ˿ں�
    /// </param>
    /// <param name="IncRefNumber">����ɹ��������Ӷ������ü��������ü�����Ҫ����Ա�Լ��ͷţ���Ȼ��һֱռ��</param>
    /// <returns>
    /// �����Ƿ����ӳɹ�
    /// </returns>
    function ConnectSer(IOCPList: TCustomIOCPBaseList; const SerAddr: string; Port: Integer;
      IncRefNumber: Integer): Boolean;
    /// <summary>
    /// ��ȡԶ��IP
    /// </summary>
    function GetRemoteIP(): string; {$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// ��ȡԶ�̶˿�
    /// </summary>
    function GetRemotePort(): Word; {$IFNDEF DEBUG} inline; {$ENDIF}

    function GetRemoteAddr(var Address: string; var Port: Word): Boolean;{$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// ��ȡԶ��IP
    /// </summary>
    function GetLocalIP(): string; {$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// ��ȡԶ�̶˿�
    /// </summary>
    function GetLocalPort(): Word; {$IFNDEF DEBUG} inline; {$ENDIF}

    function GetLocalAddr(var Address: string; var Port: Word): Boolean;{$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// ��ȡ���ܵ�����
    /// </summary>
    function GetRecvBuf(): Pointer; {$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// ���û���������
    /// </summary>
    procedure SetRecvBufLenBeforeInit(NewRecvBufLen: DWORD); inline;
    /// <summary>
    /// �������ݣ��� SendData֮ǰ������
    /// </summary>
    function SendData(Data: Pointer; DataLen: LongWord;
      UseGetSendDataFunc: Boolean = False): Boolean;

    /// <summary>
    /// ��ȡ�������ݵ�ָ��
    /// </summary>
    function GetSendData(DataLen: LongWord): Pointer; {$IFNDEF DEBUG} inline; {$ENDIF}

    /// <summary>
    /// ֻ��û�е���SendData��ʱ��ſ����ͷţ�����SendData֮�󽫻��Զ��ͷš�
    /// </summary>
    procedure FreeSendData(Data: Pointer);{$IFNDEF DEBUG} inline; {$ENDIF}
    //

    /// <summary>
    /// ����������
    /// </summary>
    function SetKeepAlive(IsOn: Boolean; KeepAliveTime: Integer = 50000;
      KeepAliveInterval: Integer = 30000): Boolean;

    /// <summary>
    /// �Ƿ��Ƿ���˽��ܵ���socket
    /// </summary>
    property IsSerSocket: Boolean read FIsSerSocket;
  end;

  /// <summary>
  /// �洢Socket�б���࣬ǰ��Ϊ��TSocketMgr��
  /// </summary>
  TCustomIOCPBaseList = class(TObject)
  private
    // �Ƿ�����ͷŴ��ڴ棬��TSocketMgr����
    FCanDestroyEvent: THandle;
    /// <summary>
    /// �Ƿ������ͷ�
    /// </summary>
    FIsFreeing: Boolean;
    /// <summary>
    /// IOCP������
    /// </summary>
    FOwner: TIOCPManager;
    /// <summary>
    /// �б��������ô���
    /// </summary>
    FLockRefNum: Integer;
    /// <summary>
    /// Iocp Socket�����̰߳�ȫ���ٽ���
    /// </summary>
    FSockBaseCS: TRTLCriticalSection;
    /// <summary>
    /// �洢TSockBase��ָ��
    /// </summary>
    FSockBaseList: TList;
    /// <summary>
    /// ��Ӷ����б���socket���б�����ʱ������ӵ����б��У��Ƚ���֮������ӵ�socket�б���
    /// </summary>
    FSockBaseAddList: TList;
    /// <summary>
    /// ɾ�������б�
    /// </summary>
    FSockBaseDelList: TList;
    /// <summary>
    /// �洢TSocketObj��ָ�룬ԭʼָ����FSockBaseList��
    /// </summary>
    FSockObjList: TList;
    /// <summary>
    /// �洢TIocpSockAcp��ָ�룬ԭʼָ����FSockBaseList��
    /// </summary>
    FSockLstList: TList;
    function GetSockBaseList: TList;
    function GetSockLstList: TList;
    function GetSockObjList: TList;
  protected
    /// <summary>
    /// ���ֻ�ǵ������ٽ�������Ҫ������Ч�������б�ʹ�� LockSockList
    /// </summary>
    procedure Lock; {$IFNDEF DEBUG}inline; {$ENDIF}
    /// <summary>
    /// ���ֻ�ǵ������ٽ�����
    /// </summary>
    procedure Unlock; {$IFNDEF DEBUG}inline; {$ENDIF}
    /// <summary>
    /// ���sockobj���б��У�����True��ʾ�ɹ�������False��ʾʧ�ܣ�ע������Ҫ����IsFreeingΪTrue�����
    /// </summary>
    function AddSockBase(SockBase: TSocketBase): Boolean;
    /// <summary>
    /// �Ƴ�sockbase����� �б���������socket������ɾ��������
    /// </summary>
    function RemoveSockBase(SockBase: TSocketBase): Boolean;
    /// <summary>
    /// ��ʼ��SockBase
    /// </summary>
    function InitSockBase(SockBase: TSocketBase): Boolean;
    /// <summary>
    /// �ͷ�sockbase���������¼�����ʱsockbase�����Ѿ����б����Ƴ�
    /// </summary>
    function FreeSockBase(SockBase: TSocketBase): Boolean;
    /// <summary>
    /// ��IOCP��������ע��SockBase
    /// </summary>
    function IOCPRegSockBase(SockBase: TSocketBase): Boolean; {$IFNDEF DEBUG}inline;
{$ENDIF}
    procedure WaitForDestroyEvent();
    /// <summary>
    /// ����Ƿ�����ͷ�
    /// </summary>
    procedure CheckCanDestroy();
    /// <summary>
    /// IOCP�¼�
    /// </summary>
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); virtual;
    /// <summary>
    /// �����¼�
    /// </summary>
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); virtual;

  public
    constructor Create(AIOCPMgr: TIOCPManager); reintroduce; virtual;
    destructor Destroy(); override;

    /// <summary>
    /// �����б�ע����������ܶ��б�������ӣ�ɾ��������һ�ж���SocketMgr��ά��
    /// </summary>
    procedure LockSockList;
    /// <summary>
    /// �����б�
    /// </summary>
    procedure UnlockSockList;
    /// <summary>
    /// ������Ϣ���������д��ڵĳ�����ʹ��
    /// </summary>
    procedure ProcessMsgEvent();

    /// <summary>
    /// �ر����е�Socket
    /// </summary>
    procedure CloseAllSockObj;
    /// <summary>
    /// �ر����е�Socklst
    /// </summary>
    procedure CloseAllSockLst;
    /// <summary>
    /// �ر����е�Socket����������socket�ͷǼ���socket
    /// </summary>
    procedure CloseAllSockBase;

    /// <summary>
    /// �����ӵ����
    /// </summary>
    property Owner: TIOCPManager read FOwner;
    property SockObjList: TList read GetSockObjList;
    property SockLstList: TList read GetSockLstList;
    property SockBaseList: TList read GetSockBaseList;


  end;

  // IOCP����ģ�͹����࣬һ��������ֻ��һ��ʵ��
  TIOCPManager = class(TObject)
  private
    FwsaData: TWSAData;
    // IOCPBaseRec�ṹ�б�
    FSockList: TList;
    // IOCPBase�����ٽ���
    FSockListCS: TRTLCriticalSection;
    // OverLapped�̰߳�ȫ�б�
    FOverLappedList: TList;
    FOverLappedListCS: TRTLCriticalSection;
    // ��ɶ˿ھ��
    FCompletionPort: THandle;
    // IOCP�߳̾����̬����
    FIocpWorkThreads: array of THandle;
    function GetSockList: TList;
    function GetOverLappedList: TList;
  protected
    procedure AddSockList(SockList: TCustomIOCPBaseList);
    procedure RemoveSockList(SockList: TCustomIOCPBaseList);
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
    /// <summary>
    /// ��ȡ����IP��ַ�б�
    /// </summary>
    /// <param name="Addrs">
    /// ��ȡ���ip��ַ������б���
    /// </param>
    class procedure GetLocalAddrs(Addrs: TStrings);

    procedure LockSockList; inline;
    property SockList: TList read GetSockList;
    procedure UnlockSockList; inline;

    procedure LockOverLappedList; inline;
    property OverLappedList: TList read GetOverLappedList;
    procedure UnlockOverLappedList; inline;
  end;

type
  // ********************* �¼� **************************
  // IOCP�¼�
  TOnIOCPBaseEvent = procedure(EventType: TIocpEventEnum; SockObj: TSocketObj;
    Overlapped: PIOCPOverlapped) of object;
  // �����¼�
  TOnListenBaseEvent = procedure(EventType: TListenEventEnum; SockLst: TSocketLst) of object;

  TIOCPBaseList = class(TCustomIOCPBaseList)
  private
    FIOCPEvent: TOnIOCPBaseEvent;
    FListenEvent: TOnListenBaseEvent;
  protected
    // IOCP�¼�
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); override;
    // �����¼�
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); override;
  public
    // �ⲿ�ӿ�
    property IOCPEvent: TOnIOCPBaseEvent read FIOCPEvent write FIOCPEvent;
    property ListenEvent: TOnListenBaseEvent read FListenEvent write FListenEvent;
  end;

implementation
var
  AcceptEx: LPFN_ACCEPTEX;
  GetAcceptExSockaddrs: LPFN_GETACCEPTEXSOCKADDRS;

procedure OutputDebugStr(const DebugInfo: string; AddLinkBreak: Boolean);
begin
{$IFDEF DEBUG}
  if AddLinkBreak then
  begin
    Windows.OutputDebugString(PChar(Format('%s'#10, [DebugInfo])));
  end
  else
  begin
    Windows.OutputDebugString(PChar(DebugInfo));
  end;
{$ENDIF}
end;

// IOCP�����߳�
function IocpWorkThread(CompletionPortID: Pointer): Integer;
var
  CompletionPort: THandle absolute CompletionPortID;
  BytesTransferred: DWORD;
  resuInt: Integer;

  SockBase: TSocketBase;
  SockObj: TSocketObj absolute SockBase;
  SockLst: TSocketLst absolute SockBase;
  _NewSockObj: TSocketObj;

  FIocpOverlapped: PIOCPOverlapped;
  FIsSuc: Boolean;

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
              SockObj.InternalDecRefCount;
              // ����
              Continue;
            end;
            // socket�¼�
            case FIocpOverlapped.OverlappedType of

              otRecv:
                begin
                  Assert(FIocpOverlapped = SockObj.FAssignedOverlapped);
                  // �ƶ���ǰ���ܵ�ָ��
                  FIocpOverlapped.RecvDataLen := BytesTransferred;
                  FIocpOverlapped.RecvData := SockObj.FRecvBuf;
                  // ��ȡ�¼�ָ��
                  // ���ͽ��

                  // �����¼�
                  try

                    SockObj.Owner.OnIOCPEvent(ieRecvAll, SockObj, FIocpOverlapped);

                  except
                    on E: Exception do
                    begin
                      OutputDebugStr(Format('Message=%s, StackTrace=%s',
                        [E.Message, E.StackTrace]));
                    end;
                  end;

                  // Ͷ����һ��WSARecv
                  if not SockObj.WSARecv() then
                  begin
                    // �������
                    OutputDebugStr(Format('WSARecv��������socket=%d:%d',
                      [SockObj.FSock, WSAGetLastError]));

                    // ��������
                    SockObj.InternalDecRefCount;
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

                    try
                      SockObj.Owner.OnIOCPEvent(ieSendAll, SockObj, FIocpOverlapped);
                    except
                      on E: Exception do
                      begin
                        OutputDebugStr(Format('Message=%s, StackTrace=%s',
                          [E.Message, E.StackTrace]));
                      end;
                    end;
                    SockObj.Owner.Owner.DelOverlapped(FIocpOverlapped);

                    // ��ȡ�����͵�����

                    FIocpOverlapped := nil;

                    SockObj.Owner.Lock;
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
                    SockObj.Owner.Unlock;

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

                        try
                          SockObj.Owner.OnIOCPEvent(ieSendFailed, SockObj,
                            FIocpOverlapped);
                        except
                          on E: Exception do
                          begin
                            OutputDebugStr(Format('Message=%s, StackTrace=%s',
                              [E.Message, E.StackTrace]));
                          end;
                        end;

                        SockObj.Owner.Owner.DelOverlapped(FIocpOverlapped);
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
                      SockObj.InternalDecRefCount;
                    end;
                  end
                  else
                  begin
                    // û��ȫ���������
                    FIocpOverlapped.DataBuf.len := FIocpOverlapped.SendDataLen +
                      UIntPtr(FIocpOverlapped.SendData) -
                      UIntPtr(FIocpOverlapped.CurSendData);
                    FIocpOverlapped.DataBuf.buf := FIocpOverlapped.CurSendData;

                    try
                      SockObj.Owner.OnIOCPEvent(ieSendPart, SockObj, FIocpOverlapped);
                    except
                      on E: Exception do
                      begin
                        OutputDebugStr(Format('Message=%s, StackTrace=%s',
                          [E.Message, E.StackTrace]));
                      end;
                    end;
                    // ����Ͷ��WSASend
                    if not SockObj.WSASend(FIocpOverlapped) then
                    begin // �������
                      OutputDebugStr(Format('WSASend��������socket=%d:%d',
                        [SockObj.FSock, WSAGetLastError]));

                      try
                        SockObj.Owner.OnIOCPEvent(ieSendFailed, SockObj, FIocpOverlapped);
                      except
                        on E: Exception do
                        begin
                          OutputDebugStr(Format('Message=%s, StackTrace=%s',
                            [E.Message, E.StackTrace]));
                        end;
                      end;

                      SockObj.Owner.Owner.DelOverlapped(FIocpOverlapped);
                      // ��������
                      SockObj.InternalDecRefCount;
                    end;
                  end;
                end;
            end;
          end;
        otListen:
          begin
            Assert(FIocpOverlapped = SockLst.FAssignedOverlapped,
              'FIocpOverlapped != SockLst.FLstOverLap');
            (*
            GetAcceptExSockaddrs(SockLst.FLstBuf, 0, SizeOf(SOCKADDR_IN) + 16,
              SizeOf(SOCKADDR_IN) + 16, local, localLen, remote, remoteLen);
            *)
            // ����������
            resuInt := setsockopt(FIocpOverlapped.AcceptSocket, SOL_SOCKET,
              SO_UPDATE_ACCEPT_CONTEXT, @SockLst.FSock, SizeOf(SockLst.FSock));
            if resuInt <> 0 then
            begin
              OutputDebugStr(Format('socket(%d)����setsockoptʧ��:%d',
                [FIocpOverlapped.AcceptSocket, WSAGetLastError()]));
            end;

            // ����
            // �����¼������SockObj�����ʧ�ܣ���close֮
            _NewSockObj := nil;
            // �����µ�SocketObj��
            SockLst.CreateSockObj(_NewSockObj);
            // ���Socket���
            _NewSockObj.FSock := FIocpOverlapped.AcceptSocket;
            // ����Ϊ����socket
            _NewSockObj.FIsSerSocket := True;
            // ��ӵ�Socket�б���
            SockLst.Owner.AddSockBase(_NewSockObj);
            
            // Ͷ����һ��Accept�˿�
            if not SockLst.Accept() then
            begin
              OutputDebugStr('AcceptEx����ʧ��: ' + IntToStr(WSAGetLastError));
              SockLst.InternalDecRefCount;
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
          SockBase.Owner.Owner.DelOverlapped(FIocpOverlapped);
        end;
        // ��������
        SockBase.InternalDecRefCount;
      end
      else
      begin
        OutputDebugStr(Format('GetQueuedCompletionStatus����ʧ��: %d', [GetLastError]));
      end;
    end;
  end;
  Result := 0;
end;

{ TSocketBase }

procedure TSocketBase.Close;
begin
  shutdown(FSock, SD_BOTH);
  if closesocket(FSock) <> ERROR_SUCCESS then
  begin
    OutputDebugStr(Format('closesocket failed:%d', [WSAGetLastError]));
  end;
  FSock := INVALID_SOCKET;
end;

constructor TSocketBase.Create;
begin
  inherited;
  FSock := INVALID_SOCKET;
  // ���ü���Ĭ��Ϊ1
  FRefCount := 0;
  // �û�����Ĭ��Ϊ0
  FUserRefCount := 0;
end;

function TSocketBase.DecRefCount(Count: Integer): Integer;
begin
  Assert(Count > 0);
  if FUserRefCount = 0 then
  begin
    raise Exception.Create
      ('IncRefCount function must be called before call this function!');
  end;
  Result := InternalDecRefCount(Count, True);
end;

destructor TSocketBase.Destroy;
begin
  if FAssignedOverlapped <> nil then
  begin
    Assert(FOwner <> nil);
    Assert(FOwner.FOwner <> nil);
    FOwner.FOwner.DelOverlapped(FAssignedOverlapped);
  end;
  inherited;
end;

function TSocketBase.IncRefCount(Count: Integer): Integer;
begin
  Assert(Count > 0);
  Result := InternalIncRefCount(Count, True);
end;

function TSocketBase.InternalDecRefCount(Count: Integer; UserMode: Boolean): Integer;
var
  // socket�Ƿ�ر�
  _IsSocketClosed1: Boolean;
  _IsSocketClosed2: Boolean;
  _CanFree: Boolean;
begin
  FOwner.Lock;
  _IsSocketClosed1 := FRefCount = FUserRefCount;
  Dec(FRefCount, Count);
  if UserMode then
  begin
    Dec(FUserRefCount, Count);
    Result := FUserRefCount;
  end
  else
  begin
    Result := FRefCount;
  end;
  _IsSocketClosed2 := FRefCount = FUserRefCount;
  _CanFree := FRefCount = 0;
  FOwner.Unlock;
  // socket�Ѿ��ر�
  if not _IsSocketClosed1 and _IsSocketClosed2 then
  begin
    // ����close�¼�
    if Self.FSocketType = STObj then
    begin
      Self.FOwner.OnIOCPEvent(ieCloseSocket, Self as TSocketObj, nil);
    end
    else
    begin
      Self.FOwner.OnListenEvent(leCloseSockLst, Self as TSocketLst);
    end;
  end;

  if _CanFree then
  begin
    // �Ƴ����������ͷ�
    FOwner.RemoveSockBase(Self);
    // ���ͷ�
    // Free;
  end;
end;

function TSocketBase.InternalIncRefCount(Count: Integer; UserMode: Boolean): Integer;
begin
  FOwner.Lock;
  Inc(FRefCount, Count);
  if UserMode then
  begin
    Inc(FUserRefCount, Count);
    Result := FUserRefCount;
  end
  else
  begin
    Result := FRefCount;
  end;
  FOwner.Unlock;
  Assert(Result > 0);
end;

{ TSocketObj }

function TSocketObj.ConnectSer(IOCPList: TCustomIOCPBaseList; const SerAddr: string;
  Port: Integer; IncRefNumber: Integer): Boolean;
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
  LastError := 0;
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

        FSock := INVALID_SOCKET;
      end
      else
      begin
        FOwner := IOCPList;
        // ��������
        IncRefCount(IncRefNumber);
        Result := IOCPList.AddSockBase(Self);
        if not Result then
        begin
          LastError := WSAGetLastError();
{$IFDEF DEBUG}
          OutputDebugStr(Format('���%s���б���ʧ�ܣ�%d', [_AddrString, LastError]));
{$ENDIF}
          closesocket(FSock);
          FSock := INVALID_SOCKET;
          // ��������
          DecRefCount(IncRefNumber);
        end;
        // *)
        Break;
      end;
    end;
    _NextAddInfo := _NextAddInfo.ai_next;

  end;
  freeaddrinfo(_ResultAddInfo);
  WSASetLastError(LastError);
end;

constructor TSocketObj.Create;
begin
  inherited;
  FSocketType := STObj;
  // ���ó�ʼ������Ϊ4096
  FRecvBufLen := 4096;
end;

destructor TSocketObj.Destroy;
var
  _TmpData: Pointer;
  _IOCPOverlapped: PIOCPOverlapped absolute _TmpData;
begin
  // if  then

  if FSendDataQueue <> nil then
  begin
    for _TmpData in FSendDataQueue do
    begin
      FOwner.Owner.DelOverlapped(_IOCPOverlapped);
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

function TSocketObj.GetLocalAddr(var Address: string; var Port: Word): Boolean;
var
  name: TSOCKADDR_STORAGE;
  namelen: Integer;
  addrbuf: array[0..NI_MAXHOST-1] of AnsiChar;
  portbuf: array[0..NI_MAXSERV-1] of AnsiChar;
begin
  Address := '';
  Port := 0;
  Result := False;

  namelen := SizeOf(name);
  if getsockname(FSock, PSockAddr(@name), namelen) = 0 then
  begin
    if (getnameinfo(PSockAddr(@name), namelen, addrbuf, NI_MAXHOST, portbuf, NI_MAXSERV, NI_NUMERICHOST or NI_NUMERICSERV)=0) then
    begin
      Address := string(addrbuf);
      Port := StrToIntDef(string(portbuf), 0);
    end;
  end;
end;

function TSocketObj.GetLocalIP: string;
var
  tmp: Word;
begin
  GetLocalAddr(Result, tmp);
end;

function TSocketObj.GetLocalPort: Word;
var
  tmp: string;
begin
  GetLocalAddr(tmp, Result);
end;

function TSocketObj.GetRecvBuf: Pointer;
begin
  Result := FRecvBuf;
end;

function TSocketObj.GetRemoteAddr(var Address: string; var Port: Word): Boolean;
var
  name: TSOCKADDR_STORAGE;
  namelen: Integer;
  addrbuf: array[0..NI_MAXHOST-1] of AnsiChar;
  portbuf: array[0..NI_MAXSERV-1] of AnsiChar;
begin
  Address := '';
  Port := 0;
  Result := False;

  namelen := SizeOf(name);
  if getpeername(FSock, PSockAddr(@name), namelen) = 0 then
  begin
    if (getnameinfo(PSockAddr(@name), namelen, addrbuf, NI_MAXHOST, portbuf, NI_MAXSERV, NI_NUMERICHOST or NI_NUMERICSERV)=0) then
    begin
      Address := string(addrbuf);
      Port := StrToIntDef(string(portbuf), 0);
    end;
  end;
end;

function TSocketObj.GetRemoteIP: string;
var
  tmp:Word;
begin
  GetRemoteAddr(result, tmp);
end;

function TSocketObj.GetRemotePort: Word;
var
  tmp: string;
begin
  GetRemoteAddr(tmp, result);
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
  _PauseSend: Boolean;
begin
  if DataLen = 0 then
  begin
    Result := True;
    Exit;
  end;
  // ����������
  InternalIncRefCount;
  _NewData := nil;
  Assert(Data <> nil);
  Result := False;

  FIocpOverlapped := FOwner.Owner.NewOverlapped(Self, otSend);
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
    FOwner.Lock;
    _PauseSend := FIsSending or (FIniteStatus = sisInitializing);
    // ������������ڷ��͵�
    if _PauseSend then
    begin
      FSendDataQueue.Add(FIocpOverlapped);
      OutputDebugStr(Format('Socket(%d)�еķ������ݼ��뵽�����Ͷ���', [Self.FSock]));
    end
    else
    begin
      FIsSending := True;
    end;
    FOwner.Unlock;

    if not _PauseSend then
    begin
      // OutputDebugStr(Format('SendData:Overlapped=%p,Overlapped=%d',[FIocpOverlapped, Integer(FIocpOverlapped.OverlappedType)]));

      if not Self.WSASend(FIocpOverlapped) then // Ͷ��WSASend
      begin
        // ����д���
        OutputDebugStr(Format('SendData:WSASend����ʧ��(socket=%d):%d',
          [FSock, WSAGetLastError]));
        // ɾ����Overlapped
        FOwner.Owner.DelOverlapped(FIocpOverlapped);

        FOwner.Lock;
        FIsSending := False;
        FOwner.Unlock;
      end
      else
      begin
        Result := True;
      end;
    end
    else
    begin
      // ��ӵ������Ͷ��е����ݲ����������ã������Ҫȡ����ǰ��Ԥ����
      InternalDecRefCount;
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
    InternalDecRefCount;
  end;
end;

function TSocketObj.SetKeepAlive(IsOn: Boolean;
  KeepAliveTime, KeepAliveInterval: Integer): Boolean;
var
  alive_in: tcp_keepalive;
  alive_out: tcp_keepalive;
  ulBytesReturn: ulong;
begin
  alive_in.KeepAliveTime := KeepAliveTime; // ��ʼ�״�KeepAlive̽��ǰ��TCP�ձ�ʱ��
  alive_in.KeepAliveInterval := KeepAliveInterval; // ����KeepAlive̽����ʱ����
  alive_in.onoff := u_long(IsOn);
  Result := WSAIoctl(FSock, SIO_KEEPALIVE_VALS, @alive_in, SizeOf(alive_in), @alive_out,
    SizeOf(alive_out), @ulBytesReturn, nil, nil) = 0;
end;

procedure TSocketObj.SetRecvBufLenBeforeInit(NewRecvBufLen: DWORD);
begin
  if FRecvBufLen <> NewRecvBufLen then
  begin
    FRecvBufLen := NewRecvBufLen;
  end;
end;

function TSocketObj.WSARecv: Boolean;
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
    @FAssignedOverlapped.lpOverlapped, nil) = 0) or (WSAGetLastError = WSA_IO_PENDING);
end;

function TSocketObj.WSASend(Overlapped: PIOCPOverlapped): Boolean;
begin
  // OutputDebugStr(Format('WSASend:Overlapped=%p,Overlapped=%d',[Overlapped, Integer(Overlapped.OverlappedType)]));
  // ���Overlapped
  ZeroMemory(@Overlapped.lpOverlapped, SizeOf(Overlapped.lpOverlapped));

  Assert(Overlapped.OverlappedType = otSend);
  Assert((Overlapped.DataBuf.buf <> nil) and (Overlapped.DataBuf.len > 0));

  Result := (LCXLWinSock2.WSASend(FSock, @Overlapped.DataBuf, 1, nil, 0,
    @Overlapped.lpOverlapped, nil) = 0) or (WSAGetLastError = WSA_IO_PENDING);
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
    OutputDebugStr('AcceptEx����ʧ��: ' + IntToStr(WSAGetLastError));
    closesocket(FAssignedOverlapped.AcceptSocket);
    FAssignedOverlapped.AcceptSocket := INVALID_SOCKET;
  end;
end;

constructor TSocketLst.Create;
begin
  inherited;
  FSocketType := STLst;
  FSocketPoolSize := 10;
  FLstBufLen := (SizeOf(sockaddr_storage) + 16) * 2;
end;

procedure TSocketLst.CreateSockObj(var SockObj: TSocketObj);
begin
  Assert(SockObj = nil);
  SockObj := TSocketObj.Create;
  SockObj.Tag := Self.Tag;
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
  if FIniteStatus = sisInitializing then
  begin
    if Value > 0 then
    begin
      FSocketPoolSize := Value;
    end;
  end
  else
  begin
    raise Exception.Create('SocketPoolSize can''t be setted after StartListen');
  end;
end;

function TSocketLst.StartListen(IOCPList: TCustomIOCPBaseList; Port: Integer;
  Family: Integer): Boolean;
var
  ErrorCode: Integer;
  _Hints: TAddrInfoA;
  _ResultAddInfo: PADDRINFOA;
  _Retval: Integer;
begin
  Result := False;
  FPort := Port;


  _Hints.ai_family := AF_UNSPEC;
  _Hints.ai_socktype := SOCK_STREAM;
  _Hints.ai_protocol := IPPROTO_TCP;
  _Hints.ai_flags := AI_PASSIVE or AI_ADDRCONFIG;
  _Retval := getaddrinfo(nil,
    PAnsiChar(AnsiString(IntToStr(Port))), @_Hints, _ResultAddInfo);
  if _Retval <> 0 then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('getaddrinfo ����ʧ�ܣ�' + IntToStr(ErrorCode));
    Exit;
  end;
  FSock := WSASocket(_ResultAddInfo.ai_family, _ResultAddInfo.ai_socktype, _ResultAddInfo.ai_protocol, nil, 0, WSA_FLAG_OVERLAPPED);
  if (FSock = INVALID_SOCKET) then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('WSASocket ����ʧ�ܣ�' + IntToStr(ErrorCode));
    freeaddrinfo(_ResultAddInfo);

    Exit;
  end;

  // �󶨶˿ں�
  if (bind(FSock, _ResultAddInfo.ai_addr, _ResultAddInfo.ai_addrlen) = SOCKET_ERROR) then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('bind ����ʧ�ܣ�' + IntToStr(ErrorCode));
    closesocket(FSock);
    freeaddrinfo(_ResultAddInfo);

    WSASetLastError(ErrorCode);
    FSock := INVALID_SOCKET;
    Exit;
  end;
  freeaddrinfo(_ResultAddInfo);
  // ��ʼ����
  if listen(FSock, SOMAXCONN) = SOCKET_ERROR then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('listen ����ʧ�ܣ�' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
    FSock := INVALID_SOCKET;
    Exit;
  end;
  FOwner := IOCPList;
  // ��ӵ�SockLst
  Result := IOCPList.AddSockBase(Self);
  if not Result then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('AddSockLst ����ʧ�ܣ�' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
    FSock := INVALID_SOCKET;

  end;
end;

{ TIOCPBaseList }

function TCustomIOCPBaseList.AddSockBase(SockBase: TSocketBase): Boolean;
var
  _IsLocked: Boolean;
begin
  Assert(SockBase.Socket <> INVALID_SOCKET);
  Assert(SockBase.RefCount >= 0);
  SockBase.FOwner := Self;
  // �������ü���+1�������ü�������Recv������
  SockBase.InternalIncRefCount;

  // ��ʼ��ʼ��Socket
  if not SockBase.Init() then
  begin

    Result := False;
    // ieCloseSocket����û�м��뵽IOCP֮ǰ�����ô���
    SockBase.Close;
    SockBase.InternalDecRefCount;

    Exit;
  end;

  Lock;
  // List�Ƿ���ס
  _IsLocked := FLockRefNum > 0;
  if _IsLocked then
  begin
    // ����ס�����ܶ�Socket�б������ӻ�ɾ���������ȼӵ�Socket�����List�С�

    FSockBaseAddList.Add(SockBase);
    OutputDebugStr(Format('�б�������Socket(%d)�������Ӷ���', [SockBase.FSock]));
  end
  else
  begin
    // û�б���ס��ֱ����ӵ�Socket�б���
    FSockBaseList.Add(SockBase);
    // ��ӵ�Ӱ��List
    if SockBase.FSocketType = STObj then
    begin
      FSockObjList.Add(SockBase);
    end
    else
    begin
      FSockLstList.Add(SockBase);
    end;
  end;
  Unlock;
  if not _IsLocked then
  begin
    // ���û�б���ס�����ʼ��Socket
    // InitSockBase(SockBase);
    // (*
    Result := InitSockBase(SockBase);
    if Result then
    begin
    end
    else
    begin
      // ��ʼ������
      Assert(SockBase.FRefCount > 0);

    end;
    // *)
  end
  else
  begin
    // �������ס���Ƿ���ֵ��Զ��True
    Result := True;
  end;

  // Result := True;
end;

procedure TCustomIOCPBaseList.CheckCanDestroy;
var
  _CanDestroy: Boolean;
begin
  Lock;
  _CanDestroy := (FSockBaseList.Count = 0) and (FSockBaseAddList.Count = 0) and
    (FSockBaseDelList.Count = 0);
  Unlock;
  if _CanDestroy then
  begin
    //
    SetEvent(FCanDestroyEvent);
  end;
end;

procedure TCustomIOCPBaseList.CloseAllSockBase;
var
  _SockBasePtr: Pointer;
  _SockBase: TSocketBase absolute _SockBasePtr;
begin
  LockSockList;
  for _SockBasePtr in FSockBaseList do
  begin
    // �ر�����
    _SockBase.Close;
  end;
  UnlockSockList;
end;

procedure TCustomIOCPBaseList.CloseAllSockLst;
var
  _SockLstPtr: Pointer;
  _SockLst: TSocketBase absolute _SockLstPtr;
begin
  LockSockList;
  for _SockLstPtr in FSockLstList do
  begin
    // �ر�����
    _SockLst.Close;
  end;
  UnlockSockList;
end;

procedure TCustomIOCPBaseList.CloseAllSockObj;
var
  _SockObjPtr: Pointer;
  _SockObj: TSocketBase absolute _SockObjPtr;
begin
  LockSockList;
  for _SockObjPtr in FSockObjList do
  begin
    // �ر�����
    _SockObj.Close;
  end;
  UnlockSockList;
end;

constructor TCustomIOCPBaseList.Create(AIOCPMgr: TIOCPManager);
begin
  inherited Create();
  FOwner := AIOCPMgr;
  FLockRefNum := 0;
  FIsFreeing := False;

  InitializeCriticalSection(FSockBaseCS);
  FSockBaseList := TList.Create;
  FSockBaseAddList := TList.Create;
  FSockBaseDelList := TList.Create;
  FSockObjList := TList.Create;
  FSockLstList := TList.Create;
  // �������
  FOwner.AddSockList(Self);
end;

destructor TCustomIOCPBaseList.Destroy;
begin
  FCanDestroyEvent := CreateEvent(nil, True, False, nil);
  FIsFreeing := True;
  CloseAllSockBase;
  CheckCanDestroy;
  WaitForDestroyEvent();

  FOwner.RemoveSockList(Self);
  CloseHandle(FCanDestroyEvent);
  FSockLstList.Free;
  FSockObjList.Free;
  FSockBaseDelList.Free;
  FSockBaseAddList.Free;
  FSockBaseList.Free;
  inherited;
end;

function TCustomIOCPBaseList.FreeSockBase(SockBase: TSocketBase): Boolean;
var
  _SockObj: TSocketObj absolute SockBase;
  _SockLst: TSocketLst absolute SockBase;

begin
  Assert(SockBase.FRefCount = 0);
  if SockBase.FSocketType = STObj then
  begin
    try
      OnIOCPEvent(ieDelSocket, _SockObj, nil);
    except

    end;
  end
  else
  begin
    try
      OnListenEvent(leDelSockLst, _SockLst);
    except

    end;
  end;
  SockBase.Free;
  if FIsFreeing then
  begin
    CheckCanDestroy;

  end;
  Result := True;
end;

function TCustomIOCPBaseList.GetSockBaseList: TList;
begin
  Result := FSockBaseList;
end;

function TCustomIOCPBaseList.GetSockLstList: TList;
begin
  Result := FSockLstList;
end;

function TCustomIOCPBaseList.GetSockObjList: TList;
begin
  Result := FSockObjList;
end;

function TCustomIOCPBaseList.InitSockBase(SockBase: TSocketBase): Boolean;
var
  _SockObj: TSocketObj absolute SockBase;
  _SockLst: TSocketLst absolute SockBase;
begin
  // Result := False;
  Result := True;
  // ���뵽�����˵���Ѿ���ӵ�socket�б����ˣ�����Ҫ����
  try
    if SockBase.FSocketType = STObj then
    begin
      OnIOCPEvent(ieAddSocket, _SockObj, nil);
    end
    else
    begin
      OnListenEvent(leAddSockLst, _SockLst);
    end;
  except

  end;

  // ����

  Assert(SockBase.FRefCount > 0);
  // ��ӵ�Mgr
  if not IOCPRegSockBase(SockBase) then
  begin
    // ʧ�ܣ�
    // ieCloseSocket���Լ��ֶ�����
    SockBase.Close;
    SockBase.InternalDecRefCount;
    Exit;
  end;
  // Result := True;
  // ע�ᵽϵͳ��IOCP�в����ʼ�����
  Lock;
  SockBase.FIniteStatus := sisInitialized;
  Unlock;

  if SockBase.FSocketType = STObj then
  begin
    // ���Recv��Overlapped
    _SockObj.FAssignedOverlapped := FOwner.NewOverlapped(_SockObj, otRecv);
    if not _SockObj.WSARecv() then // Ͷ��WSARecv
    begin // �������
      OutputDebugStr(Format('InitSockObj:WSARecv��������socket=%d:%d',
        [_SockObj.FSock, WSAGetLastError]));

      try
        OnIOCPEvent(ieRecvFailed, _SockObj, _SockObj.FAssignedOverlapped);
      except

      end;

      // ��������
      SockBase.InternalDecRefCount;
    end;
  end
  else
  begin
    // ���Listen��Overlapped
    _SockLst.FAssignedOverlapped := FOwner.NewOverlapped(_SockLst, otListen);
    if not _SockLst.Accept() then // Ͷ��AcceptEx
    begin
      // ��������
      SockBase.InternalDecRefCount;
    end;
  end;

end;

function TCustomIOCPBaseList.IOCPRegSockBase(SockBase: TSocketBase): Boolean;
begin
  // ��IOCP��ע���Socket
  SockBase.FIOComp := CreateIoCompletionPort(SockBase.FSock, FOwner.FCompletionPort,
    ULONG_PTR(SockBase), 0);
  Result := SockBase.FIOComp <> 0;
  if not Result then
  begin
    OutputDebugStr(Format('Socket(%d)IOCPע��ʧ�ܣ�Error:%d',
      [SockBase.FSock, WSAGetLastError()]));
  end;
end;

procedure TCustomIOCPBaseList.Lock;
begin
  EnterCriticalSection(FSockBaseCS);
end;

procedure TCustomIOCPBaseList.LockSockList;
begin
  Lock;
  Assert(FLockRefNum >= 0);
  Inc(FLockRefNum);
  Unlock;
end;

procedure TCustomIOCPBaseList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
begin

end;

procedure TCustomIOCPBaseList.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin

end;

procedure TCustomIOCPBaseList.ProcessMsgEvent;

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

function TCustomIOCPBaseList.RemoveSockBase(SockBase: TSocketBase): Boolean;
var
  _IsLocked: Boolean;
begin
  Assert(SockBase.FRefCount = 0);
  Lock;
  _IsLocked := FLockRefNum > 0;
  if not _IsLocked then
  begin
    FSockBaseList.Remove(SockBase);
    if SockBase.FSocketType = STObj then
    begin
      FSockObjList.Remove(SockBase);
    end
    else
    begin
      FSockLstList.Remove(SockBase);
    end;
  end
  else
  begin
    FSockBaseDelList.Add(SockBase);
  end;
  Unlock;
  if not _IsLocked then
  begin
    FreeSockBase(SockBase);
  end;
  Result := True;
end;

procedure TCustomIOCPBaseList.Unlock;
begin
  LeaveCriticalSection(FSockBaseCS);
end;

procedure TCustomIOCPBaseList.UnlockSockList;

var
  isAdd: Boolean;
  _SockBase: TSocketBase;
  _SockObj: TSocketObj absolute _SockBase;
  _SockLst: TSocketLst absolute _SockBase;
  _IsEnd: Boolean;
begin
  isAdd := False;
  repeat
    _SockBase := nil;
    Lock;
    Assert(FLockRefNum >= 1, 'Socket�б������߳�������');
    // �ж��ǲ���ֻ�б��߳��������б�ֻҪ�ж�FLockRefNum�ǲ��Ǵ���1
    _IsEnd := FLockRefNum > 1;
    if not _IsEnd then
    begin
      // ֻ�б��߳���ס��socket��Ȼ��鿴socketɾ���б��Ƿ�Ϊ��
      if FSockBaseDelList.Count > 0 then
      begin
        // ��Ϊ�գ��ӵ�һ����ʼɾ
        _SockBase := FSockBaseDelList.Items[0];
        FSockBaseDelList.Delete(0);

        FSockBaseList.Remove(_SockBase);
        if _SockBase.FSocketType = STObj then
        begin
          FSockObjList.Remove(_SockObj);
        end
        else
        begin
          FSockLstList.Remove(_SockLst);
        end;
        isAdd := False;
      end
      else
      begin
        // �鿴socket����б��Ƿ�Ϊ��
        if FSockBaseAddList.Count > 0 then
        begin
          isAdd := True;
          // �����Ϊ�գ���popһ��sockobj��ӵ��б���
          _SockBase := FSockBaseAddList.Items[0];
          FSockBaseAddList.Delete(0);
          FSockBaseList.Add(_SockBase);
          if _SockBase.FSocketType = STObj then
          begin
            FSockObjList.Add(_SockObj);
          end
          else
          begin
            FSockLstList.Add(_SockLst);
          end;
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
    if _SockBase <> nil then
    begin

      if isAdd then
      begin
        // �����sock��������ʼ��sockobj�����ʧ�ܣ����Զ���Free���������ȡ����ֵ
        InitSockBase(_SockBase);
      end
      else
      begin
        // ��ɾ��sock������ɾ��sockobk
        // InitSockBase(_SockBase);
        // RemoveSockBase(_SockBase);
        Assert(_SockBase.FRefCount = 0);
        // _SockBase.Free;
        FreeSockBase(_SockBase);
      end;
    end;
  until _IsEnd;
end;

procedure TCustomIOCPBaseList.WaitForDestroyEvent;
const
  EVENT_NUMBER = 1;
var
  _IsEnd: Boolean;
  EventArray: array [0 .. EVENT_NUMBER - 1] of THandle;
begin
  EventArray[0] := FCanDestroyEvent;
  _IsEnd := False;
  // �ȴ��ͷ�����¼�
  while not _IsEnd do
  begin
    case MsgWaitForMultipleObjects(EVENT_NUMBER, EventArray[0], False, INFINITE, QS_ALLINPUT) of
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

{ TIOCPManager }

procedure TIOCPManager.AddSockList(SockList: TCustomIOCPBaseList);
begin
  LockSockList;
  FSockList.Add(SockList);
  UnlockSockList;
end;

constructor TIOCPManager.Create(IOCPThreadCount: Integer);
var
  ThreadID: DWORD;
  I: Integer;
  TmpSock: TSocket;
  dwBytes: DWORD;
begin
  inherited Create();
  //IsMultiThread := True;
  OutputDebugStr('IOCPManager::IOCPManager');
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
  InitializeCriticalSection(FSockListCS);
  FSockList := TList.Create;

  InitializeCriticalSection(FOverLappedListCS);
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
    //BeginThread()
    FIocpWorkThreads[I] := BeginThread(nil, 0, @IocpWorkThread, Pointer(FCompletionPort),
      0, ThreadID);
    (*
    FIocpWorkThreads[I] := CreateThread(nil, 0, @IocpWorkThread, Pointer(FCompletionPort),
      0, ThreadID);
    *)
    if FIocpWorkThreads[I] = 0 then
    begin
      raise Exception.Create('CreateThread FIocpWorkThreads Fails');
    end;
  end;
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

destructor TIOCPManager.Destroy;
var
  Resu: Boolean;

begin

  // �ر����е�Socket
  // ����
  LockSockList;
  try
    if FSockList.Count > 0 then
    begin
      raise Exception.Create('SockList����ȫ���ͷ�');
    end;
  finally
    UnlockSockList;
  end;

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
  DeleteCriticalSection(FOverLappedListCS);

  Assert(FSockList.Count = 0,
    'FSockMgrList.Count <> 0, you must free ALL TIOCPOBJBase class before free this class.');
  FSockList.Free;
  FSockList := nil;
  DeleteCriticalSection(FSockListCS);
  // �ر�Socket
  WSACleanup;
  inherited;
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

class procedure TIOCPManager.GetLocalAddrs(Addrs: TStrings);
var
  sHostName: AnsiString;
  _Hints: TAddrInfoA;
  _ResultAddInfo: PADDRINFOA;
  _NextAddInfo: PADDRINFOA;
  _Retval: Integer;
  _AddrString: string;
  _AddrStringLen: DWORD;
begin
  Addrs.Clear;
  SetLength(sHostName, MAX_PATH);
  if gethostname(PAnsiChar(sHostName), MAX_PATH) = SOCKET_ERROR then
  begin
    Exit;
  end;

  ZeroMemory(@_Hints, SizeOf(_Hints));
  _Hints.ai_family := AF_UNSPEC;
  _Hints.ai_socktype := SOCK_STREAM;
  _Hints.ai_protocol := IPPROTO_TCP;

  _Retval := getaddrinfo(PAnsiChar(sHostName), nil, @_Hints, _ResultAddInfo);
  if _Retval <> 0 then
  begin
    Exit;
  end;
  _NextAddInfo := _ResultAddInfo;

  while _NextAddInfo <> nil do
  begin
    _AddrStringLen := 256;
    // ���뻺����
    SetLength(_AddrString, _AddrStringLen);
    // ��ȡ
    if WSAAddressToString(_NextAddInfo.ai_addr, _NextAddInfo.ai_addrlen, nil,
      PChar(_AddrString), _AddrStringLen) = 0 then
    begin
      // ��Ϊ��ʵ����,�����_AddrStringLen������ĩβ���ַ�#0������Ҫ��ȥ���#0�ĳ���
      SetLength(_AddrString, _AddrStringLen - 1);
      Addrs.Add(_AddrString);
    end
    else
    begin
      OutputDebugStr('WSAAddressToString Error');
    end;

    _NextAddInfo := _NextAddInfo.ai_next;

  end;
  freeaddrinfo(_ResultAddInfo);

end;

function TIOCPManager.GetOverLappedList: TList;
begin
  Result := FOverLappedList;
end;

function TIOCPManager.GetSockList: TList;
begin
  Result := FSockList;
end;

procedure TIOCPManager.LockOverLappedList;
begin
  EnterCriticalSection(FOverLappedListCS);
end;

procedure TIOCPManager.LockSockList;
begin
  EnterCriticalSection(FSockListCS);
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

procedure TIOCPManager.RemoveSockList(SockList: TCustomIOCPBaseList);
begin
  LockSockList;
  FSockList.Remove(SockList);
  UnlockSockList;
end;

procedure TIOCPManager.UnlockOverLappedList;
begin
  LeaveCriticalSection(FOverLappedListCS);
end;

procedure TIOCPManager.UnlockSockList;
begin
  LeaveCriticalSection(FSockListCS);
end;

{ TIOCPBase2List }

procedure TIOCPBaseList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
begin
  if Assigned(FIOCPEvent) then
  begin
    FIOCPEvent(EventType, SockObj, Overlapped);
  end;

end;

procedure TIOCPBaseList.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin
  if Assigned(FListenEvent) then
  begin
    FListenEvent(EventType, SockLst);
  end;

end;

end.
