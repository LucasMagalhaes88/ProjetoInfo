unit UCadastroCliente;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Buttons, ToolWin, ExtCtrls, Mask, DBXJSON, DBXJSONReflect,  idHTTP, IdSSLOpenSSL,
  IdBaseComponent, IdComponent, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP, IdMessage, IdAttachmentFile,
  DB, JvMemoryDataset, IdServerIOHandler;

type
  TfrmCadastroCliente = class(TForm)
    pnlPrincipal: TPanel;
    ToolBar1: TToolBar;
    btnIncluir: TBitBtn;
    btnSalvar: TBitBtn;
    btnCancelar: TBitBtn;
    ToolButton1: TToolButton;
    btnSair: TBitBtn;
    edtNome: TEdit;
    Label19: TLabel;
    mkeCPF: TMaskEdit;
    lblCPF: TLabel;
    edtIdentidade: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edtEmail: TEdit;
    mkeTelefone: TMaskEdit;
    Label3: TLabel;
    Label23: TLabel;
    mkeCEP: TMaskEdit;
    btnCEP: TBitBtn;
    Label4: TLabel;
    edtLogradouro: TEdit;
    Label5: TLabel;
    edtNumero: TEdit;
    Label6: TLabel;
    edtComplemento: TEdit;
    Label20: TLabel;
    edtBairro: TEdit;
    Label7: TLabel;
    edtEstado: TEdit;
    edtCidade: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    edtPais: TEdit;
    IdSMTP: TIdSMTP;
    IdSSLIOHandlerSocketOpenSSL: TIdSSLIOHandlerSocketOpenSSL;
    IdMessage: TIdMessage;
    mdtMemoria: TJvMemoryData;
    mdtMemoriaNOME: TStringField;
    mdtMemoriaCPF: TStringField;
    mdtMemoriaIDENTIDADE: TStringField;
    mdtMemoriaTELEFONE: TStringField;
    mdtMemoriaEMAIL: TStringField;
    mdtMemoriaCEP: TStringField;
    mdtMemoriaLOGRADOURO: TStringField;
    mdtMemoriaNUMERO: TStringField;
    mdtMemoriaCOMPLEMENTO: TStringField;
    mdtMemoriaBAIRRO: TStringField;
    mdtMemoriaCIDADE: TStringField;
    mdtMemoriaUF: TStringField;
    mdtMemoriaPAIS: TStringField;
    btnImprimir: TBitBtn;
    procedure btnSairClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnIncluirClick(Sender: TObject);
    procedure btnCEPClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
  private
    { Private declarations }
    procedure CodigoOnEnter(Sender : TObject);
    procedure CodigoOnExit(Sender : TObject);
    function  ValidaCpf(numero: string): boolean;
    function ValidaTelefone(sTelefone:String): Boolean;
    function ValidaEMail(const EMailIn: String):Boolean;
    function ValidaUF(UF: String):Boolean;
    function ValidaCEP(sCep:String): Boolean;
    function GetCEP(CEP:string): String;
    procedure CarregaCEP(dados: string);
    procedure LimpaCamposCEP();
  public
    { Public declarations }
  end;

var
  frmCadastroCliente: TfrmCadastroCliente;

implementation

{$R *.dfm}

procedure TfrmCadastroCliente.LimpaCamposCEP();
begin
  edtLogradouro.Text:='';
  edtNumero.Text:='';
  edtComplemento.Text:='';
  edtBairro.Text:='';
  edtCidade.Text:='';
  edtEstado.Text:='';
  edtPais.Text:='';
end;


function TfrmCadastroCliente.GetCEP(CEP: string): string;
var
   HTTP: TIdHTTP;
   IDSSLHandler : TIdSSLIOHandlerSocketOpenSSL;
   Response: TStringStream;
   LJsonObj: TJSONObject;
begin
   try
      HTTP := TIdHTTP.Create;
      IDSSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create;
      HTTP.IOHandler := IDSSLHandler;
      Response := TStringStream.Create('');
      HTTP.Get('http://viacep.com.br/ws/' + CEP + '/json', Response);
      if (HTTP.ResponseCode = 200) and not(Utf8ToAnsi(Response.DataString) = '{'#$A'  "erro": true'#$A'}') then
         //Result := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes( Utf8ToAnsi(Response.DataString)), 0) as TJSONObject;
         Result := Utf8ToAnsi(Response.DataString)
      else
        Result := '';
   finally
      FreeAndNil(HTTP);
      FreeAndNil(IDSSLHandler);
      Response.Destroy;
   end;
end;

procedure TfrmCadastroCliente.CarregaCEP(dados: string);
var item, informacao: string;
    i, j: integer;
begin
  LimpaCamposCEP;
  dados:=StringReplace(dados, #$A, '', [rfReplaceAll]);
  while (pos('"', dados)>0) do
  begin
    i:=pos('"', dados);
    dados:=Copy(dados, i+1, Length(dados));
    i:=pos('"', dados);
    item:=Copy(dados,0,i-1);
    dados:=Copy(dados, i, Length(dados));
    i:=pos(':', dados);
    dados:=Copy(dados, i+3, Length(dados));
    i:=pos('"', dados);
    informacao:=Copy(dados,0,i-1);
    dados:=Copy(dados, i+3, Length(dados));

    if item = 'logradouro' then
      edtLogradouro.Text := informacao
    else
    if item = 'complemento' then
      edtComplemento.Text := informacao
    else
    if item = 'bairro' then
      edtBairro.Text := informacao
    else
    if item = 'localidade' then
    begin
      edtCidade.Text := informacao;
      edtPais.Text   := 'BRASIL';
    end
    else
    if item = 'uf' then
      edtEstado.Text := informacao;
  end;
  edtNumero.SetFocus;
end;


function TfrmCadastroCliente.ValidaCEP(sCep:String): Boolean;
var i : byte;   n: string;
begin
  if sCep<>'     -   ' then
  begin
    Result := Length(sCep) = 9 ;
    if (Result) then
    begin
      for i := 1 to 9 do
         if sCep[i] in ['0'..'9'] then
             n := n + sCep[i];
      Result := Length(n) = 8;
    end;
  end
  else
    Result:=true;
end;

function TfrmCadastroCliente.ValidaTelefone(sTelefone:String): Boolean;
var i : byte;   n: string;
begin
  if (sTelefone<>'(  )    -    ') and (sTelefone<>'(  )     -    ') then
  begin
    if Length(sTelefone) = 13 then
      Result := true
    else
    if Length(sTelefone) = 14 then
      Result := true
    else
      Result := false;
    if (Result) then
    begin
      for i := 1 to Length(sTelefone) do
         if sTelefone[i] in ['0'..'9'] then
             n := n + sTelefone[i];
      if Length(n) = 10 then
        Result := true
      else
      if Length(n) = 11 then
        Result := true
      else
        Result := false;
    end;
  end
  else
    Result:=true;
end;

Function TfrmCadastroCliente.ValidaUF(UF: String):Boolean;
const Estados = 'SPMGRJRSSCPRESDFMTMSGOTOBASEALPBPEMARNCEPIPAAMAPFNACRRRO';
var
  Posicao : integer;
begin
  Result := true;
  if UF <>'' then
  begin
    Posicao := Pos(UpperCase(UF), Estados);
    if (Posicao = 0) or ((Posicao mod 2) = 0) then
      Result := false;
  end;
end;

Function TfrmCadastroCliente.ValidaEMail(const EMailIn: String):Boolean;
const
  CaraEsp: array[1..41] of string[1] =
  ( '!','#','$','%','¨','&','*',
  '(',')','+','=','§','¬','¢','¹','²',
  '³','£','´','`','ç','Ç',',',';',':',
  '<','>','~','^','?','/','','|','[',']','{','}',
  'º','ª','°',' ');
var
  i,cont   : integer;
  EMail    : ShortString;
begin
  EMail := EMailIn;
  Result := True;
  cont := 0;
  if EMail <> '' then
    if (Pos('@', EMail)<>0) and (Pos('.', EMail)<>0) then    // existe @ .
    begin
      if (Pos('@', EMail)=1) or (Pos('@', EMail)= Length(EMail)) or (Pos('.', EMail)=1) or (Pos('.', EMail)= Length(EMail)) or (Pos(' ', EMail)<>0) then
        Result := False
      else                                   // @ seguido de . e vice-versa
      if (abs(Pos('@', EMail) - Pos('.', EMail)) = 1) then
        Result := False
      else
      begin
        for i := 1 to 40 do            // se existe Caracter Especial
          if Pos(CaraEsp[i], EMail)<>0 then
            Result := False;
        for i := 1 to length(EMail) do
        begin                                 // se existe apenas 1 @
          if EMail[i] = '@' then
            cont := cont + 1;                    // . seguidos de .
          if (EMail[i] = '.') and (EMail[i+1] = '.') then
            Result := false;
        end;
                               // . no f, 2ou+ @, . no i, - no i, _ no i
        if (cont >=2) or ( EMail[length(EMail)]= '.' )
          or ( EMail[1]= '.' ) or ( EMail[1]= '_' )
          or ( EMail[1]= '-' )  then
            Result := false;
                                        // @ seguido de COM e vice-versa
        if (abs(Pos('@', EMail) - Pos('com.', EMail)) = 1) then
          Result := False;
                                          // @ seguido de - e vice-versa
        if (abs(Pos('@', EMail) - Pos('-', EMail)) = 1) then
          Result := False;
      end;
    end
    else
      Result := False;
end;

function TfrmCadastroCliente.ValidaCPF(numero: string): boolean;
var i, s0, d1, d2: SmallInt;
  n, ultNumero: string;
  numerosRepetidos: Boolean;
begin
  if (numero<>'   .   .   -  ') then
  begin
    numerosRepetidos:=true;
    ultNumero:='';
    for i := 1 to length(numero) do
      if numero[i] in ['0'..'9'] then
      begin
        if (ultNumero<>'') and (numero[i]<>ultNumero) then
          numerosRepetidos:=False;
        ultNumero:=numero[i];
        n := n + numero[i];
      end;
    if numerosRepetidos then
      result := False
    else
    begin
      numero := Copy('00000000000000' + n, length('00000000000000' + n) - 13, 14);
      s0 := 0;
      d1 := 0;
      d2 := 0;
      for i := 1 to 28 do
      begin
        if length(n) = 14 then
          s0 := s0 + StrToInt(Copy(numero + numero, i, 1)) * (StrToInt(Copy('4321876543210054321876543200', i, 1)) + 1);
        if length(n) = 11 then
          s0 := s0 + StrToInt(Copy(numero + numero, i, 1)) * (StrToInt(Copy('0008765432100000098765432100', i, 1)) + 2);
        if (i = 12) and ((11 - (s0 mod 11)) < 10) then
          d1 := 11 - (s0 mod 11);
        if (i = 14) then
          s0 := d1 * 2;
        if (i = 26) and ((11 - (s0 mod 11)) < 10) then
          d2 := 11 - (s0 mod 11);
      end;
      result := ((length(n) in [11, 14]) and (StrToInt(copy(numero, 13, 2)) = (d1 * 10 + d2)));
    end;
  end
  else
    Result:= true;
end;

procedure TfrmCadastroCliente.CodigoOnEnter(Sender: TObject);
begin
  if (Sender is TEdit)then
    TEdit(Sender).Color := clActiveBorder
  else
  if (Sender is TMaskEdit) then
    TMaskEdit(Sender).Color := clActiveBorder;
end;

procedure TfrmCadastroCliente.CodigoOnExit(Sender: TObject);
begin
  if (Sender is TEdit)then
  begin
    TEdit(Sender).Color := clWindow;

    if (TEdit(Sender).Name = 'edtEmail') and (not ValidaEMail(edtEmail.Text))then
    begin
      MessageDlg ('Email Inválido!', mtError, [mbOk], 0);
      TEdit(Sender).SetFocus;
    end;
    if (TEdit(Sender).Name = 'edtEstado') and (not ValidaUF(edtEstado.Text))then
    begin
      MessageDlg ('UF Inválida!', mtError, [mbOk], 0);
      TEdit(Sender).SetFocus;
    end;
  end
  else
  if (Sender is TMaskEdit) then
  begin
    TMaskEdit(Sender).Color := clWindow;
    if (TMaskEdit(Sender).Name = 'mkeCPF') and (not ValidaCPF(mkeCPF.Text)) then
    begin
      MessageDlg ('CPF Inválido!', mtError, [mbOk], 0);
      TMaskEdit(Sender).SetFocus;
    end;

    if (TMaskEdit(Sender).Name = 'mkeTelefone') and (not ValidaTelefone(mkeTelefone.Text))then
    begin
      MessageDlg ('Telefone Inválido!', mtError, [mbOk], 0);
      TMaskEdit(Sender).SetFocus;
    end;

    if (TMaskEdit(Sender).Name = 'mkeCEP') and (not ValidaCEP(mkeCEP.Text))then
    begin
      MessageDlg ('CEP Inválido!', mtError, [mbOk], 0);
      TMaskEdit(Sender).SetFocus;
    end;
  end;
end;


procedure TfrmCadastroCliente.btnCancelarClick(Sender: TObject);
var i: integer;
begin
  btnIncluir.Enabled:=true;
  btnSalvar.Enabled:=false;
  btnCancelar.Enabled:=false;
  btnImprimir.Enabled:=true;
  btnSair.Enabled:=true;
  pnlPrincipal.Enabled:=false;
  for I := 0 to Self.ComponentCount - 1 do
  begin
    if(Self.Components[I]) is TEdit then
      TEdit(Self.Components[I]).Text:=''
    else
    if(Self.Components[I]) is TMaskEdit then
      TMaskEdit(Self.Components[I]).Text:='';
  end;
end;

procedure TfrmCadastroCliente.btnCEPClick(Sender: TObject);
var LJsonObj: TJSONObject;
    i: integer;
    vCEP, retorno: string;
begin
  vCEP:='';
  for i := 1 to Length(mkeCEP.Text) do
    if mkeCEP.Text[i] in ['0'..'9'] then
      vCEP := vCEP + mkeCEP.Text[i];


   if length(vCEP) <> 8 then
   begin
      MessageDlg('CEP Inválido!', mtError, [mbOk], 0);
      LimpaCamposCEP;
      mkeCEP.SetFocus;
      exit;
   end;

   retorno := GetCEP(vCEP);
   if retorno<>'' then
      CarregaCEP(retorno)
   else
   begin
      MessageDlg('CEP Inválido ou Não Encontrado', mtError, [mbOk], 0);
      LimpaCamposCEP;
      mkeCEP.SetFocus;
      exit;
   end;
end;

procedure TfrmCadastroCliente.btnImprimirClick(Sender: TObject);
var mensagem: String;
begin
  mdtMemoria.First;
  if mdtMemoria.Eof then
    MessageDlg('Nenhum Cliente Cadastrado!', mtError, [mbOk], 0)
  else
  begin
    mensagem:='CADASTROS REALIZADOS: '#13;
    while not mdtMemoria.Eof do
    begin
      mensagem:=mensagem+mdtMemoria['NOME']+#13;
      mdtMemoria.Next;
    end;
    MessageDlg(mensagem, mtInformation, [mbOk], 0);
  end;
end;

procedure TfrmCadastroCliente.btnIncluirClick(Sender: TObject);
begin
  btnIncluir.Enabled:=false;
  btnSalvar.Enabled:=true;
  btnCancelar.Enabled:=true;
  btnImprimir.Enabled:=false;
  btnSair.Enabled:=false;
  pnlPrincipal.Enabled:=true;
  edtNome.SetFocus;
  mkeCEP.Text:='19020-600'; //apenas para teste
  edtNome.Text:='Lucas BM';
  edtEmail.Text:='lucasbmagalhaes@hotmail.com';
end;

procedure TfrmCadastroCliente.btnSairClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmCadastroCliente.btnSalvarClick(Sender: TObject);
var stXML:TStringList;
   i, IDTagDetail:integer;
   arquivo: string;
begin
  if edtNome.Text = '' then
  begin
    MessageDlg('Informar o Nome do Cliente Anteriormente!', mtError, [mbOk], 0);
    edtNome.SetFocus;
  end
  else
  begin
    try
      //Cria o XML
      stXML:=TStringList.Create;
      stXML.Add('<?xml version="1.0"?>');
      stXML.Add('<Dados_Cliente>');
      if edtNome.Text<>'' then
        stXML.Add('<Nome>'+edtNome.Text+'</Nome>');
      if mkeCPF.Text<>'   .   .   -  ' then
        stXML.Add('<CPF>'+mkeCPF.Text+'</CPF>');
      if edtIdentidade.Text<>'' then
        stXML.Add('<Identidade>'+edtIdentidade.Text+'</Identidade>');
      if mkeTelefone.Text<>'(  )     -    ' then
        stXML.Add('<Telefone>'+mkeTelefone.Text+'</Telefone>');
      if edtEmail.Text<>'' then
        stXML.Add('<Email>'+edtEmail.Text+'</Email>');

      stXML.Add('<Dados_Endereco>');
      if mkeCEP.Text<>'     -   ' then
        stXML.Add('<CEP>'+mkeCEP.Text+'</CEP>');
      if edtLogradouro.Text<>'' then
        stXML.Add('<Logradouro>'+edtLogradouro.Text+'</Logradouro>');
      if edtNumero.Text<>'' then
        stXML.Add('<Numero>'+edtNumero.Text+'</Numero>');
      if edtComplemento.Text<>'' then
        stXML.Add('<Complemento>'+edtComplemento.Text+'</Complemento>');
      if edtBairro.Text<>'' then
        stXML.Add('<Bairro>'+edtBairro.Text+'</Bairro>');
      if edtCidade.Text<>'' then
        stXML.Add('<Cidade>'+edtCidade.Text+'</Cidade>');
      if edtEstado.Text<>'' then
        stXML.Add('<Estado>'+edtEstado.Text+'</Estado>');
      if edtPais.Text<>'' then
        stXML.Add('<Pais>'+edtPais.Text+'</Pais>');
      stXML.Add('</Dados_Endereco>');
      stXML.Add('</Dados_Cliente>');
      arquivo:=ExtractFilePath(Application.ExeName)+'\Dados_Cliente.xml';
      stXML.SaveToFile(arquivo);

      if edtEmail.Text<>'' then
      begin //envia email
        IdMessage.From.Name :='Projeto Lucas - INFO';
        IdMessage.From.Address :='teste.empresa.info@gmail.com';
        IdMessage.Recipients.EMailAddresses := edtEmail.Text;
        IdMessage.Subject := 'Cliente Cadastrado';
        IdMessage.Date := now;
        IdMessage.Body.Clear;
        IdMessage.Body.Add('Cliente Cadastrado: '+ edtNome.Text);
        if mkeCPF.Text<>'   .   .   -  ' then
          IdMessage.Body.Add('CPF: '+ mkeCPF.Text);
        if edtIdentidade.Text<>'' then
          IdMessage.Body.Add('Identidade: '+edtIdentidade.Text);
        if mkeTelefone.Text<>'(  )     -    ' then
          IdMessage.Body.Add('Telefone: '+mkeTelefone.Text);
        if edtEmail.Text<>'' then
          IdMessage.Body.Add('Email: '+edtEmail.Text);
        IdMessage.Body.Add('');
        IdMessage.Body.Add('Dados Endereço:');
        if mkeCEP.Text<>'     -   ' then
          IdMessage.Body.Add('CEP: '+mkeCEP.Text);
        if edtLogradouro.Text<>'' then
          IdMessage.Body.Add('Logradouro: '+edtLogradouro.Text);
        if edtNumero.Text<>'' then
          IdMessage.Body.Add('Numero: '+edtNumero.Text);
        if edtComplemento.Text<>'' then
          IdMessage.Body.Add('Complemento: '+edtComplemento.Text);
        if edtBairro.Text<>'' then
          IdMessage.Body.Add('Bairro: '+edtBairro.Text);
        if edtCidade.Text<>'' then
          IdMessage.Body.Add('Cidade: '+edtCidade.Text);
        if edtEstado.Text<>'' then
          IdMessage.Body.Add('Estado: '+edtEstado.Text);
        if edtPais.Text<>'' then
          IdMessage.Body.Add('País: '+edtPais.Text);
        IdMessage.MessageParts.Clear;
        if FileExists(arquivo) then
          TIdAttachmentFile.Create(IdMessage.MessageParts, arquivo);
        IdSMTP.Connect();
        try
          IdSMTP.Send(IdMessage);
          MessageDlg('Email Enviado Para o Cliente!', mtInformation, [mbOk], 0);
        finally
          IdSMTP.Disconnect;
        end;
      end
      else
        MessageDlg('Email Não Enviado Por Falta de Informação do Email do Cliente!', mtInformation, [mbOk], 0);

      //Armazena na memória
      mdtMemoria.Append;
      mdtMemoria['NOME'] := edtNome.Text;
      mdtMemoria['CPF'] := mkeCPF.Text;
      mdtMemoria['IDENTIDADE'] := edtIdentidade.Text;
      mdtMemoria['TELEFONE'] := mkeTelefone.Text;
      mdtMemoria['EMAIL'] := edtEmail.Text;
      mdtMemoria['CEP'] := mkeCEP.Text;
      mdtMemoria['LOGRADOURO'] := edtLogradouro.Text;
      mdtMemoria['NUMERO'] := edtNumero.Text;
      mdtMemoria['COMPLEMENTO'] := edtComplemento.Text;
      mdtMemoria['BAIRRO'] := edtBairro.Text;
      mdtMemoria['CIDADE'] := edtCidade.Text;
      mdtMemoria['UF'] := edtEstado.Text;
      mdtMemoria['PAIS'] := edtPais.Text;
      mdtMemoria.Post;

      btnCancelarClick(nil);
    finally
      FreeAndNil(stXML);
    end;
  end;
end;

procedure TfrmCadastroCliente.FormCreate(Sender: TObject);
var i: integer;
begin
  mdtMemoria.Close;
  mdtMemoria.Open;
  btnCancelarClick(nil);

  for I := 0 to ComponentCount - 1 do
  begin
    if (Components[I] is TEdit) then
    begin
      (Components[I] as TEdit).OnEnter := CodigoOnEnter;
      (Components[I] as TEdit).OnExit  := CodigoOnExit;
    end
    else
    if (Components[I] is TMaskEdit) then
    begin
      (Components[I] as TMaskEdit).OnEnter := CodigoOnEnter;
      (Components[I] as TMaskEdit).OnExit  := CodigoOnExit;
    end;
  end;
end;

procedure TfrmCadastroCliente.FormKeyPress(Sender: TObject; var Key: Char);
begin
   if key=#27 then //Esc
   begin
     if (btnSalvar.Enabled) and (MessageDlg ('Deseja Cancelar?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
       btnCancelarClick(nil)
     else
     if (not btnSalvar.Enabled) and (MessageDlg ('Deseja Fechar o Sistema?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
       btnSairClick(nil);
   end;
end;

end.
