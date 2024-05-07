#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#Include 'FwMvcDef.ch'

/*/{Protheus.doc} FDEPURA
Função de chamada direta de programas para realização de testes com depuração

@author 		Michel Sander
@since 		25/07/2022
@version 	12.1.33
/*/    

User Function FDepura()

	Local cModulo 	:= 'SIGAEST' // Nome do Modulo

	MsApp():New(cModulo) 					// Instancia o módulo
	oApp:cInternet := NIL					// Instancia módulo front-end
	oApp:CreateEnv() 							// Cria o ambiente que será usado
	PtSetTheme("OCEAN") 						// Define o nome do tema (se omitir será considerado o tema padrão)
	oApp:cStartProg   :=  'U_RFATM07' 	// Instancia a user function que será executada
	oApp:lMessageBar	:= .T.
	oApp:cModDesc		:= cModulo
	__lInternet 		:= .T.
	lMsFinalAuto 		:= .F.
	oApp:lMessageBar	:= .T.
	oApp:Activate() 							// Executa

Return

/*/{Protheus.doc} RFATM07
Rotina para coleta de pedidos pela transportadora

@author 		Michel Sander
@since 		25/08/2022
@version 	12.1.33
/*/    

User function RFATM07()

	LOCAL aCamposC5 	:= {}
	LOCAL aBrowse   	:= {}
	LOCAL aSeek       := {}
	LOCAL cCampo 		:= ""
	LOCAL nX				:= 0

	PRIVATE oBrowse
	PRIVATE cAliasTMP  := ""
	PRIVATE cAliasSC5  := ""
	PRIVATE aIndex		 := {}
	PRIVATE aCamposVis := { "C5_FILIAL","C5_NUM","C5_XNUMCOL","C5_CLIENTE", "C5_LOJACLI", "C5_NOMCLI","C5_TRANSP",;
									"C5_NOMTRA","C5_PLACA1","C5_XNOMMOT","C5_XCARRO","C5_XNFFAT","C5_XSERFAT","C5_XDTPREV",;
									"C5_XHRPREV","C5_XDTACOL","C5_XHRACOL","C5_XRETIRA","C5_PESOL","C5_ESPECI1","C5_VOLUME1",;
									"C5_XATEND","C5_MENNOTA"}

	//Configura campos do browse
	SX3->(dbSetorder(2))
	For nX := 1 To Len(aCamposVis)
		cCampo  := aCamposVis[nX]
		If SC5->(FieldPos(cCampo)) == 0 .And. ( cCampo != "C5_NOMTRA" )
			ApMsgStop("A execução não será permitida. Campo "+cCampo+" não encontrado no dicionário de dados da tabela SC5.")
			RETURN 
		EndIf
		// Insere campos virtuais
		If cCampo == "C5_NOMTRA"
			AADD(aCamposC5, { cCampo, "C", 40, 0 } )
			AADD(aBrowse, {"Nome da Transportadora", cCampo, "C", 40, 0, "@!"})
		Else
			SX3->(dbSeek(aCamposVis[nX]))
			AADD(aCamposC5, { AllTrim(SX3->X3_CAMPO)		, SX3->X3_TIPO,  SX3->X3_TAMANHO, SX3->X3_DECIMAL } )
			AADD(aBrowse, 	 { FWX3Titulo(SX3->X3_CAMPO)	, SX3->X3_CAMPO, SX3->X3_TIPO, 	 SX3->X3_TAMANHO, SX3->X3_DECIMAL, "@!"})
		EndIf
	Next

	// Cria a tabela temporária
	cAliasTMP := GetNextAlias()
	cAliasSC5 := GetNextAlias()
	oTmpSC5 	 := FWTemporaryTable():New(cAliasTMP)
	oTmpSC5:SetFields( aCamposC5 )
	oTmpSC5:AddIndex("01",{'C5_FILIAL','C5_NUM'})
	oTmpSC5:Create()

	// Seleciona os registros que irão para a tabela temporária
	BEGINSQL Alias cAliasSC5
	SELECT C5_FILIAL, C5_NUM, C5_CLIENTE, C5_LOJACLI, C5_TRANSP, C5_XNUMCOL, C5_XNFFAT, C5_XSERFAT,
				C5_XDTPREV, C5_XHRPREV, C5_XDTACOL, C5_XHRACOL, C5_XNOMMOT, C5_PLACA1,
				C5_XCARRO, C5_XRETIRA, C5_PESOL, C5_ESPECI1, C5_VOLUME1, C5_MENNOTA, C5_XATEND
				FROM %Table:SC5% SC5
				WHERE C5_FILIAL = %Exp:xFilial("SC5")% AND
						C5_NOTA <> '' AND
						C5_XSEPARA = 'S' AND
						SC5.%NotDel%
	ENDSQL

	// Popula a tabela temporária utilizada no browse
	While (cAliasSC5)->(!Eof())
		Reclock(cAliasTMP,.T.)
		(cAliasTMP)->C5_FILIAL 	:= (cAliasSC5)->C5_FILIAL
		(cAliasTMP)->C5_NUM 		:= (cAliasSC5)->C5_NUM
		(cAliasTMP)->C5_CLIENTE := (cAliasSC5)->C5_CLIENTE
		(cAliasTMP)->C5_LOJACLI	:= (cAliasSC5)->C5_LOJACLI
		(cAliasTMP)->C5_NOMCLI 	:= Posicione("SA1",1,xFilial("SA1")+(cAliasSC5)->C5_CLIENTE+(cAliasSC5)->C5_LOJACLI,"A1_NREDUZ")
		(cAliasTMP)->C5_TRANSP 	:= (cAliasSC5)->C5_TRANSP
		(cAliasTMP)->C5_NOMTRA 	:= Posicione("SA4",1,xFilial("SA4")+(cAliasSC5)->C5_TRANSP,"A4_NOME")
		(cAliasTMP)->C5_XNUMCOL	:= (cAliasSC5)->C5_XNUMCOL
		(cAliasTMP)->C5_XNFFAT  := (cAliasSC5)->C5_XNFFAT
		(cAliasTMP)->C5_XSERFAT := (cAliasSC5)->C5_XSERFAT
		(cAliasTMP)->C5_XDTPREV := STOD((cAliasSC5)->C5_XDTPREV)
		(cAliasTMP)->C5_XHRPREV := (cAliasSC5)->C5_XHRPREV
		(cAliasTMP)->C5_XDTACOL := STOD((cAliasSC5)->C5_XDTACOL)
		(cAliasTMP)->C5_XHRACOL := (cAliasSC5)->C5_XHRACOL
		(cAliasTMP)->C5_PLACA1  := (cAliasSC5)->C5_PLACA1
		(cAliasTMP)->C5_XNOMMOT := (cAliasSC5)->C5_XNOMMOT
		(cAliasTMP)->C5_XCARRO  := (cAliasSC5)->C5_XCARRO
		If Empty((cAliasSC5)->C5_XRETIRA)
			(cAliasTMP)->C5_XRETIRA := "N"
		Else 
			(cAliasTMP)->C5_XRETIRA := (cAliasSC5)->C5_XRETIRA
		EndIf 
		(cAliasTMP)->C5_PESOL   := (cAliasSC5)->C5_PESOL
		(cAliasTMP)->C5_ESPECI1 := (cAliasSC5)->C5_ESPECI1
		(cAliasTMP)->C5_VOLUME1 := (cAliasSC5)->C5_VOLUME1
		(cAliasTMP)->C5_XATEND  := (cAliasSC5)->C5_XATEND
		(cAliasTMP)->(MsUnlock())
		(cAliasSC5)->(dbSkip())
	End

	// Prepara os índices
	(cAliasTMP)->(dbGotop())
	aIndex := {'C5_FILIAL','C5_NUM'}
	aSeek := {{"Filial+Num. Pedido" , {{ FWX3Titulo('C5_FILIAL'), "C", 02, 0, "C5_FILIAL" ,"@!" },{ FWX3Titulo('C5_NUM'), "C", 06, 0, "C5_NUM" ,"@!" }}}}

	//Cria Browse dos pedidos de venda
	(cAliasSC5)->(dbCloseArea())
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias( (cAliasTMP) )
	oBrowse:AddLegend("Empty(C5_XNUMCOL)", 'GREEN', 'Pedido disponível para coleta')
	oBrowse:AddLegend("!Empty(C5_XNUMCOL) .And. ( C5_XRETIRA =='N' .Or. Empty(C5_XRETIRA) )",'NGBIOALERTA_01',	'Pedido com coleta pendente')
	oBrowse:AddLegend("!Empty(C5_XNUMCOL) .And. C5_XRETIRA =='S'",'TMSIMG32', 	'Pedido coletado pela Transportadora')
	oBrowse:SetMenuDef("RFATM07")
	oBrowse:SetQueryIndex(aIndex)
	oBrowse:SetSeek(.T.,aSeek)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetFields(aBrowse)
	oBrowse:SetDescription('Coleta de Pedidos')
	oBrowse:DisableDetails()
	oBrowse:Activate()

	oTmpSC5:Delete()

Return NIL

/*/{Protheus.doc} MENUDEF()
Botões de menu

@author 		Michel Sander
@since 		25/08/2022
@version 	12.1.33
/*/    

Static Function MenuDef()

	Local aMnu 			:= {}
	PRIVATE aRotina 	:= {}
	PRIVATE cCadastro := "Coleta de Pedidos"

	ADD OPTION aMnu TITLE 'Coleta'	  ACTION 'U_RFATM12' OPERATION 2 ACCESS 0
	ADD OPTION aMnu TITLE 'Visualiza'  ACTION 'U_RFATM11'	OPERATION 2 ACCESS 0
	ADD OPTION aMnu TITLE 'Estorno'    ACTION 'U_RFATM09'	OPERATION 2 ACCESS 0
	ADD OPTION aMnu TITLE 'Ver Pedido' ACTION 'U_RFATM05' OPERATION 2 ACCESS 0
	ADD OPTION aMnu TITLE 'Legenda'    ACTION 'U_RFATM10'	OPERATION 2 ACCESS 0

Return aMnu

/*/{Protheus.doc} RFATM10
Tela de apresentação das legendas

@type 	function
@author 	Michel Sander
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

User Function RFATM10()

	LOCAL aLegenda := {}

	aAdd(aLegenda, {"TMSIMG32" 		, "Pedido coletado pela Transportadora" })
	aAdd(aLegenda, {"NGBIOALERTA_01" , "Pedido aguardando coleta da Transportadora"    })
	aAdd(aLegenda, {"BR_VERDE"   	 	, "Pedido disponível para coleta" })
	BrwLegenda( "Status", "Legenda", aLegenda)

Return Nil

/*/{Protheus.doc} ModelDef
Controle ModelDef do MVC

@author 	Michel Sander
@since 	25/08/2022
@version P12.1.023 
/*/ 

Static Function ModelDef()

	LOCAL nQ 		 := 0
	Local oModel 	 := Nil
	LOCAL aCbo   	 := {}
	LOCAL lChave	
	Local oStTMP 	 

	// Cria o modelo 
	oStTmp:= FWFormModelStruct():New()
	oStTMP:AddTable(cAliasTmp, aIndex, "Temporária")
	
	// Adiciona Trigger ao campo Transportadora
	aAux := FwStruTrigger(;
			"C5_TRANSP" ,; 
			"C5_NOMTRA" ,; 
			"SA4->A4_NOME",;
			.T. ,; 
			"SA4" ,;
			1 ,; 
			"xFilial('SA4')+M->C5_TRANSP" ,; 
			NIL ,; 
			"01" ) 
	
	oStTmp:AddTrigger( aAux[1] , aAux[2] , aAux[3] , aAux[4] )
		
	// Cria os campos do modelo
	SX3->(dbSetorder(2))
	For nQ := 1 to Len(aCamposVis)
		lChave := IIf( aCamposVis[nQ] $ "C5_FILIAL|C5_NUM", .T., .F.)
		aCbo   := IIF( aCamposVis[nQ] == "C5_XRETIRA", {"S=Sim","N=Nao"},{})
		If SX3->(dbSeek(aCamposVis[nQ]))
			//Adiciona os campos da estrutura
			oStTmp:AddField(AllTrim(FWX3Titulo(aCamposVis[nQ])),AllTrim(FWX3Titulo(aCamposVis[nQ])),aCamposVis[nQ],SX3->X3_TIPO,SX3->X3_TAMANHO,SX3->X3_DECIMAL,NIL,NIL,aCbo,.F.,FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTmp+"->"+aCamposVis[nQ]+",'')" ),lChave,.F.,.F.)
		EndIf
		If aCamposVis[nQ] == "C5_NOMTRA"
			oStTmp:AddField("Nome da Transportadora","Nome da Transportadora","C5_NOMTRA","C",40,0,NIL,NIL,aCbo,.F.,FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTmp+"->"+aCamposVis[nQ]+",'')" ),lChave,.F.,.F.)
		EndIf
	Next

	// Muda as propriedades dos campos do modelo de dados
	oStTmp:SetProperty('C5_XNUMCOL' , MODEL_FIELD_OBRIGAT, .T.  )
	oStTmp:SetProperty('C5_CLIENTE' , MODEL_FIELD_WHEN,{|| .F. })
	oStTmp:SetProperty('C5_LOJACLI' , MODEL_FIELD_WHEN,{|| .F. })
	oStTmp:SetProperty('C5_NOMCLI'  , MODEL_FIELD_WHEN,{|| .F. })
	oStTmp:SetProperty('C5_NOMTRA'  , MODEL_FIELD_WHEN,{|| .F. })
	oStTmp:SetProperty('C5_PESOL'   , MODEL_FIELD_WHEN,{|| .F. })
	oStTmp:SetProperty('C5_ESPECI1' , MODEL_FIELD_WHEN,{|| .F. })
	oStTmp:SetProperty('C5_VOLUME1' , MODEL_FIELD_WHEN,{|| .F. })
	oStTmp:SetProperty('C5_MENNOTA' , MODEL_FIELD_WHEN,{|| .F. })
	oStTmp:SetProperty('C5_XSERFAT' , MODEL_FIELD_VALID, {||fTrigger(2)})
	oStTmp:SetProperty('C5_TRANSP'  , MODEL_FIELD_OBRIGAT, .T.  )
	oStTmp:SetProperty('C5_TRANSP'  , MODEL_FIELD_VALID, {||fTrigger(3)})

	// Habilta o modelo MVC
	bSair 	 := {|| .T. } 
	bPreValid := {|| .T. }
	bPosValid := {|| .T. }
	bCommit   := {|| fUpdColeta((cAliasTmp)->C5_FILIAL,(cAliasTmp)->C5_NUM) }
	oModel := MPFormModel():New("RFATM07M",bPreValid, bPosValid, bCommit, bSair)
	oModel:AddFields("FORMTMP",/*cOwner*/,oStTMP)
	oModel:SetPrimaryKey( aIndex )
	oModel:SetDescription("Coleta de Pedidos")
	oModel:GetModel("FORMTMP"):SetDescription("Dados da Transportadora")

Return oModel

/*/{Protheus.doc} ViewDef
Controle da View do MVC

@author 	Michel Sander
@since 	25/08/2022
@version P12.1.023 
/*/ 

Static Function ViewDef()

	Local aStruTMP  := {}
	Local oModel    := FWLoadModel("RFATM07")
	Local oVwTMP    := FWFormViewStruct():New()
	Local oView     := Nil
	Local nW        := nOrd := 0
	LOCAL lAltera 

	aStruTMP := (cAliasTmp)->(DbStruct())

	// Prepara os campos da View
	SX3->(dbSetorder(2))
	For nW := 1 to Len(aStruTMP)
		nOrd++
		lAltera := IIf( aCamposVis[nW] $ "C5_FILIAL|C5_NUM", .F., .T.)
		If SX3->(dbSeek(aStruTMP[nW,1]))
			//Adicionando campos da estrutura
			oVwTmp:AddField(AllTrim(SX3->X3_CAMPO),StrZero(nOrd,2),AllTrim(SX3->X3_TITULO),AllTrim(SX3->X3_DESCRIC),{},SX3->X3_TIPO,SX3->X3_PICTURE,NIL,"",lAltera,NIL,NIL,NIL,NIL,NIL,NIL,NIL)
		EndIf
		If aStruTMP[nW,1] == "C5_NOMTRA"
			oVwTmp:AddField(AllTrim(aStruTMP[nW,1]),StrZero(nOrd,2),"Nome","Nome da Transportadora",{},aStruTMP[nW,2],"@!",NIL,"",.T.,NIL,NIL,NIL,NIL,NIL,NIL,NIL)
		EndIf
	Next

	// Configura as propriedades dos campos da view
	oVwTmp:RemoveField("C5_FILIAL")
	oVwTmp:SetProperty('C5_NUM'		, MVC_VIEW_TITULO    , "Num. Pedido")
	oVwTmp:SetProperty('C5_PLACA1'	, MVC_VIEW_TITULO    , "Placa")
	oVwTmp:SetProperty('C5_TRANSP'	, MVC_VIEW_LOOKUP    , "SA4")
	oVwTmp:SetProperty('C5_XNFFAT'	, MVC_VIEW_LOOKUP    , "SF2")
	oVwTmp:SetProperty('C5_VOLUME1'	, MVC_VIEW_PICT	   , "99999.99")
	oVwTmp:SetProperty('C5_VOLUME1'	, MVC_VIEW_WIDTH     , 30)
	oVwTmp:SetProperty('C5_NOMTRA'	, MVC_VIEW_WIDTH     , 120)	
	oVwTmp:SetProperty('C5_VOLUME1'	, MVC_VIEW_TITULO    , 'Volume')	
	oVwTmp:SetProperty('C5_ESPECI1'	, MVC_VIEW_TITULO    , 'Espécie')
	oVwTmp:SetProperty('C5_XHRPREV'	, MVC_VIEW_PICT      , "99:99")
	oVwTmp:SetProperty('C5_XHRACOL'	, MVC_VIEW_PICT      , "99:99")	
	oVwTmp:SetProperty('C5_XRETIRA'  , MVC_VIEW_COMBOBOX, {'S=Sim',"N=Nao" })
	oVwTmp:SetProperty('C5_XATEND'   , MVC_VIEW_ORDEM	, "04"	)

	// Habilita a view do modelo de dados
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_TMP", oVwTMP, "FORMTMP")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_TMP', 'Dados da Transportadora')
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_TMP","TELA")

Return oView

/*/{Protheus.doc} RFATM12
Pre-validação dos dados de entrada

@author 	Michel Sander
@since 	25/08/2022
@version P12.1.023 
/*/ 

User Function RFATM12()

	Local lValid := .T.	

	// Verifica se houve coleta
	If (cAliasTMP)->C5_XRETIRA=="S"
		ApMsgInfo("A coleta para esse pedido já foi realizada. Para uma nova coleta, estorne os dados da coleta atual.")	
		lValid := .F.
	EndIf 

	If lValid
	   FWExecView( "Coleta de Pedidos" , "RFATM07", MODEL_OPERATION_UPDATE, , {|| .T. })
	EndIf 

Return

/*/{Protheus.doc} FUpdColeta
Atualiza os dados da Coleta

@author 	Michel Sander
@since 	25/08/2022
@version P12.1.023 
/*/ 

Static Function fUpdColeta(xFilCol, xNumCol)

	LOCAL lUpd := .F.
	LOCAL oModelUpd
	LOCAL oUpd
	
	oModelUpd	:= FwModelActive()
	oUpd 	  		:= oModelUpd:GetModel("FORMTMP")

	// Altera os dados digitados
	SC5->(dbSetOrder(1))
	SC5->(dbSeek(xFilCol+xNumCol))
	If Reclock("SC5",.F.)
	   SC5->C5_XNUMCOL := oUpd:GetValue("C5_XNUMCOL")
		SC5->C5_TRANSP  := oUpd:GetValue("C5_TRANSP")
		SC5->C5_XDTACOL := oUpd:GetValue("C5_XDTACOL")
		SC5->C5_XHRACOL := oUpd:GetValue("C5_XHRACOL")
		SC5->C5_XDTPREV := oUpd:GetValue("C5_XDTPREV")
		SC5->C5_XHRPREV := oUpd:GetValue("C5_XHRPREV")
		SC5->C5_XRETIRA := oUpd:GetValue("C5_XRETIRA")
		SC5->C5_XCARRO  := oUpd:GetValue("C5_XCARRO")
		SC5->C5_PLACA1  := oUpd:GetValue("C5_PLACA1")
		SC5->C5_XNOMMOT := oUpd:GetValue("C5_XNOMMOT")
		SC5->C5_XNFFAT  := oUpd:GetValue("C5_XNFFAT")
		SC5->C5_XSERFAT := oUpd:GetValue("C5_XSERFAT")
		SC5->C5_XATEND  := oUpd:GetValue("C5_XATEND")
		SC5->(MsUnlock())
		lUpd := .T.
	Else 
		ApMsgStop("O pedido encontra-se bloqueado por outro usuário. Aguarde um instante e tente novamente.")
	EndIf

	If lUpd 
	   Reclock(cAliasTmp,.F.)
		(cAliasTmp)->C5_XNUMCOL := oUpd:GetValue("C5_XNUMCOL")
		(cAliasTmp)->C5_TRANSP  := oUpd:GetValue("C5_TRANSP")
		(cAliasTmp)->C5_NOMTRA  := oUpd:GetValue("C5_NOMTRA")
		(cAliasTmp)->C5_XDTACOL := oUpd:GetValue("C5_XDTACOL")
		(cAliasTmp)->C5_XHRACOL := oUpd:GetValue("C5_XHRACOL")
		(cAliasTmp)->C5_XDTPREV := oUpd:GetValue("C5_XDTPREV")
		(cAliasTmp)->C5_XHRPREV := oUpd:GetValue("C5_XHRPREV")
		(cAliasTmp)->C5_XRETIRA := oUpd:GetValue("C5_XRETIRA")
		(cAliasTmp)->C5_XCARRO  := oUpd:GetValue("C5_XCARRO")
		(cAliasTmp)->C5_PLACA1  := oUpd:GetValue("C5_PLACA1")
		(cAliasTmp)->C5_XNOMMOT := oUpd:GetValue("C5_XNOMMOT")
		(cAliasTmp)->C5_XNFFAT  := oUpd:GetValue("C5_XNFFAT")
		(cAliasTmp)->C5_XSERFAT := oUpd:GetValue("C5_XSERFAT")
		(cAliasTMP)->C5_PESOL   := oUpd:GetValue("C5_PESOL")
		(cAliasTMP)->C5_ESPECI1 := oUpd:GetValue("C5_ESPECI1")
		(cAliasTMP)->C5_VOLUME1 := oUpd:GetValue("C5_VOLUME1")
		(cAliasTMP)->C5_MENNOTA := oUpd:GetValue("C5_MENNOTA")
		(cAliasTMP)->C5_XATEND  := oUpd:GetValue("C5_XATEND")
		(cAliasTmp)->(MsUnlock())
	EndIf 

	oBrowse:Refresh()

Return ( lUpd )

/*/{Protheus.doc} RFATM09
Estorna os dados da coleta

@author 	Michel Sander
@since 	25/08/2022
@version P12.1.023 
/*/ 

User Function RFATM09()

	LOCAL lUpd := .F.
	
	If Empty((cAliasTmp)->C5_TRANSP)
		ApMsgStop("Coleta ainda não realizada. Não há dados para serem estornados.")
		Return 
	EndIf 

	If ApMsgYesNo("Deseja realmente estornar os dados da Coleta desse Pedido?")

		// Realiza o estorno dos dados
		SC5->(dbSetOrder(1))
		If SC5->(dbSeek((cAliasTmp)->C5_FILIAL+(cAliasTmp)->C5_NUM))
			Reclock("SC5",.F.)
			SC5->C5_XNUMCOL := ""
			SC5->C5_TRANSP  := ""
			SC5->C5_XDTACOL := Ctod("")
			SC5->C5_XHRACOL := ""
			SC5->C5_XDTPREV := Ctod("")
			SC5->C5_XHRPREV := ""
			SC5->C5_XRETIRA := "N"
			SC5->C5_XCARRO  := ""
			SC5->C5_PLACA1  := ""
			SC5->C5_XNOMMOT := ""
			SC5->C5_XNFFAT  := ""
			SC5->C5_XSERFAT := ""
			SC5->C5_XATEND  := ""
			SC5->(MsUnlock())
			lUpd := .T.
		Else 
			ApMsgStop("O pedido encontra-se bloqueado por outro usuário. Aguarde um instante e tente novamente.")
		EndIf

		If lUpd 
			Reclock(cAliasTmp,.F.)
			(cAliasTmp)->C5_XNUMCOL := ""
			(cAliasTmp)->C5_TRANSP  := ""
			(cAliasTmp)->C5_XDTACOL := Ctod("")
			(cAliasTmp)->C5_XHRACOL := ""
			(cAliasTmp)->C5_XDTPREV := Ctod("")
			(cAliasTmp)->C5_XHRPREV := ""
			(cAliasTmp)->C5_XRETIRA := "N"
			(cAliasTmp)->C5_XCARRO  := ""
			(cAliasTmp)->C5_PLACA1  := ""
			(cAliasTmp)->C5_XNOMMOT := ""
			(cAliasTmp)->C5_XNFFAT  := ""
			(cAliasTmp)->C5_XSERFAT := ""
			(cAliasTMP)->C5_PESOL   := 0
			(cAliasTMP)->C5_ESPECI1 := ""
			(cAliasTMP)->C5_VOLUME1 := 0
			(cAliasTMP)->C5_MENNOTA := ""
			(cAliasTMP)->C5_XATEND  := ""
			(cAliasTmp)->(MsUnlock())
		EndIf 

	EndIf 

	oBrowse:Refresh()

Return ( lUpd )

/*/{Protheus.doc} F0103509
Visualiza os dados da coleta

@author 	Michel Sander
@since 	25/08/2022
@version P12.1.023 
/*/ 

User Function RFATM11()

	LOCAL nCount   := 0
	LOCAL aNodes   := {}
	LOCAL IMAGE1   := "" 	// Imagem quando nível estiver fechado
	LOCAL IMAGE2   := "" 	// Imagem quando nível estiver aberto

	DEFINE DIALOG oDlg TITLE "Rastreamento" FROM 180,180 TO 750,1000 PIXEL

	aNodes   := {}
	IMAGE1  := "" 	// Imagem quando nível estiver fechado
	IMAGE2  := "" 	// Imagem quando nível estiver aberto

	// Cria a árvore com o conjunto dos campos da coleta
	nCount++
	IMAGE1 := "AVGBOX1"
	aadd( aNodes, {'00', StrZero(nCount,4), "", "Numero da Coleta: "+AllTrim((cAliasTmp)->C5_XNUMCOL), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "TMKIMG32"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Nome do Atendente: "+AllTrim((cAliasTmp)->C5_XATEND), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "TMSIMG32"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Nome da Transportadora: "+AllTrim((cAliasTmp)->C5_NOMTRA), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "AGENDA_INSERIR"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Data Prevista da Coleta: "+AllTrim(Dtoc((cAliasTmp)->C5_XDTPREV)), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "OPERACAO"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Hora Prevista da Coleta: "+AllTrim((cAliasTmp)->C5_XHRPREV), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "AGENDA_INSERIR"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Data da Coleta efetiva: "+AllTrim(Dtoc((cAliasTmp)->C5_XDTACOL)), IMAGE1, IMAGE2} )
	nCount++			
	IMAGE1 := "OPERACAO"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Hora da Coleta efetiva: "+AllTrim((cAliasTmp)->C5_XHRACOL), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "DBG05_OCEAN"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Nota Fiscal/Serie: "+AllTrim((cAliasTmp)->C5_XNFFAT+"/"+(cAliasTmp)->C5_XSERFAT), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "ARMIMG32"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Peso Liquido: "+AllTrim(Transform((cAliasTmp)->C5_PESOL,X3Picture("C5_PESOL"))), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "CONTAINR"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Especie: "+AllTrim((cAliasTmp)->C5_ESPECI1), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "ESTIMG32"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Volume: "+AllTrim((cAliasTmp)->C5_VOLUME1), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "CARGA_OCEAN"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Placa do Veículo:  "+AllTrim((cAliasTmp)->C5_PLACA1), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "LVEIMG32"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Descrição do Veículo: "+AllTrim((cAliasTmp)->C5_XCARRO), IMAGE1, IMAGE2} )
	nCount++
	IMAGE1 := "BMPUSER"
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Nome do Motorista: "+AllTrim((cAliasTmp)->C5_XNOMMOT), IMAGE1, IMAGE2} )
	nCount++
	If (cAliasTmp)->C5_XRETIRA=="S"
		IMAGE1 := "NGBIOALERTA_02"
	Else 
		IMAGE1 := "NGBIOALERTA_01"
	EndIf 
	aadd( aNodes, {'01', StrZero(nCount,4), "", "Status da Coleta: "+IIF((cAliasTmp)->C5_XRETIRA=="S","COLETADO","AGUARDANDO COLETA"), IMAGE1, IMAGE2} )
	nCount++

	// Cria o objeto Tree
	oTree := DbTree():New(0,0,260,405,oDlg,,,.T.)

	// Método para carga dos itens da Tree
	oTree:PTSendTree( aNodes )

	@ 265 , 320 BUTTON oBtn PROMPT "Concluir" SIZE 080, 015 OF oDlg ;
		ACTION { || oDlg:End() } PIXEL
	oBtn:SetCss("QPushButton:pressed { background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #dadbde, stop: 1 #f6f7fa); }")

	ACTIVATE DIALOG oDlg CENTERED

Return

/*/{Protheus.doc} RetFldCbox
Monta o combobox do campo C5_XRETIRA

@author 	Michel Sander
@since 	25/08/2022
@version P12.1.023 
/*/ 

Static Function RetFldCbox(cField)

	Local aCbox := {}

	Do Case
		Case cField == "C5_XRETIRA"
			aAdd(aCbox,"S=Sim")
			aAdd(aCbox,"N=Nao")
	EndCase

Return aCbox

/*/{Protheus.doc} fTrigger
Dispara o gatilho no campo posicionado

@type 	function
@author 	Michel Sander
@since 	28/08/2022
@Date 	11/07/2022
@version 1.0
/*/

Static Function fTrigger(xParam)
	
	LOCAL aArea 		:= GetArea()
	LOCAL oGTModel		:= FWModelActive()
	LOCAL oModelNF		:= oGTModel:GetModel("FORMTMP")
	LOCAL lGatilho    := .T.

	SF2->(dbSetOrder(1))
	SA4->(dbSetOrder(1))

	If xParam == 1
		If !SF2->(dbSeek(xFilial("SF2")+oModelNF:GetValue("C5_XNFFAT")))
			Help("",1,"Não encontrado",,"Número de Nota Fiscal de saída não existe.",1,0)
			lGatilho := .F.
		EndIf
	ElseIf xParam == 2 
		If !SF2->(dbSeek(xFilial("SF2")+oModelNF:GetValue("C5_XNFFAT")+oModelNF:GetValue("C5_XSERFAT")+(cAliasTMP)->C5_CLIENTE+(cAliasTMP)->C5_LOJACLI))
			Help("",1,"Não encontrado",,"Nota Fiscal/Serie de saída não existe.",1,0)
			lGatilho := .F.
		EndIf
	ElseIf xParam == 3 
		If !SA4->(dbSeek(xFilial("SA4")+oModelNF:GetValue("C5_TRANSP")))
			Help("",1,"Não encontrado",,"Transportadora não existe.",1,0)
			lGatilho := .F.
		EndIf
	EndIf 

	RestArea(aArea)

RETURN lGatilho
