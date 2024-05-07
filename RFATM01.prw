#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#Include 'FwMvcDef.ch'

/*/{Protheus.doc} RFATM01
Rotina de separação para faturamento (romaneio de carga)

@author 		MIchel Sander
@since 		25/07/2022
@version 	12.1.33
/*/    

User function RFATM01()
	
	Local oBrowse
	
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('SC5')
	oBrowse:SetDescription('Liberação de Pedidos')
	oBrowse:SetFilterDefault("Empty(C5_NOTA) .And. Empty(C5_BLQ)")
	oBrowse:AddLegend("Empty(C5_XSEPARA) .Or. C5_XSEPARA == 'N'", 'YELLOW', 'Separação não iniciada')
	oBrowse:AddLegend("C5_XSEPARA == 'S'",'CARGA_OCEAN'	, 	'Aguardando Faturamento')
	oBrowse:AddLegend("C5_XSEPARA == 'P'",'BLUE'		, 	'Separação Pendente')	
	oBrowse:AddLegend("C5_XSEPARA == 'O'",'GREEN'	,	'Separação Concluída')
	oBrowse:SetMenuDef("RFATM01")
	oBrowse:Activate()

Return NIL

Static Function MENUDEF()
	
	Local aMnu 			:= {}
	PRIVATE aRotina 	:= {}
	PRIVATE cCadastro := "Pedido de Venda"

	ADD OPTION aMnu TITLE 'Pesquisar'  ACTION 'PesqBrw'       OPERATION 1 ACCESS 0
	ADD OPTION aMnu TITLE 'Romaneio'   ACTION 'U_RFATM02'		 OPERATION 3 ACCESS 0
	ADD OPTION aMnu TITLE 'Estorno'    ACTION 'U_RFATM04'		 OPERATION 2 ACCESS 0
	ADD OPTION aMnu TITLE 'Ver Pedido' ACTION 'U_RFATM05'     OPERATION 2 ACCESS 0 
	ADD OPTION aMnu TITLE 'Legenda'    ACTION 'U_RFATM03'		 OPERATION 2 ACCESS 0

Return aMnu

/*/{Protheus.doc} RFATM03
Tela de apresentação das legendas

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

User Function RFATM03()

	Local  _aLegenda := {}

	aAdd(_aLegenda, {"CARGA_OCEAN" , "Aguardando Faturamento" })
	aAdd(_aLegenda, {"BR_AMARELO" , "Aguardando Separação"    })
	aAdd(_aLegenda, {"BR_AZUL"    , "Separação Pendente" })
	aAdd(_aLegenda, {"BR_VERDE"   , "Separação Concluída" })
	
	BrwLegenda( "Status", "Legenda", _aLegenda)

Return Nil

/*/{Protheus.doc} RFATM01A
Tela para leitura de dados

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

User Function RFATM02()

	Private oOk  		:= LoadBitmap(GetResources(), "BR_VERDE")
	Private oNOk 		:= LoadBitmap(GetResources(), "BR_VERMELHO")
	Private oChecked  := LoadBitMap(GetResources(), "BR_VERDE")
	Private oNChecked := LoadBitMap(GetResources(), "BR_VERMELHO")
	Private oPendente := LoadBitMap(GetResources(), "BR_AZUL")
	Private oColetado := LoadBitMap(GetResources(), "BR_VERDE")
	Private oNIniciado:= LoadBitMap(GetResources(), "BR_VERMELHO")	
	Private _nTamEtiq   := 14
	Private cEtiqueta   := Space(_nTamEtiq)
	Private cSitPedido  := Space(08)
	Private aFields     := {}
	Private aQtdEtiq    := {}
	Private cProdBip    := SPACE(15)
	Private cDescBip    := SPACE(45)
	Private cPedBip     := SPACE(06)
	Private aItemBloq     := {}
	Private nTotBloqueio  := 0
	Private nTotColeta  := 0
	Private nResto      := 1
	Private nSaldoBip   := 0
	Private lSair       := .F.
	Private oSeparar
	Private oEntregar 
	Private oGetBloqueio
	Private oGetColeta
	Private oGetResto
	Private oGetSld
			
	// Verifica bloqueio do pedido
	If !fVerBloq()
		Return 
	EndIf 

	// Posição inicial da tela principal	 						
	nLin := 15
	nCol1 := 10
	nCol2 := 95

	AADD(aItemBloq, { .F., " ", Space(16), Space(15), Space(45), Space(04), 0, 0, 0 })
	cPedBip := SC5->C5_NUM	

	Do While !lSair

		DEFINE MSDIALOG oDlg01 TITLE OemToAnsi("RFATM01- Romaneio de Carga") FROM 0,0 TO 600,1350 PIXEL of oMainWnd PIXEL //300,400 PIXEL of oMainWnd PIXEL
		
		@ nLin-13,nCol1-05  TO nLin+100,nCol1+495 LABEL " Informações do Pedido de Venda " OF oDlg01 PIXEL
		@ nLin-13,nCol1+500 TO nLin+280,nCol1+662 LABEL " Totalizador "							 OF oDlg01 PIXEL 	// Linha horizontal para separar botões

		// Número do Pedido
		@ nLin+5, nCol1 SAY oTexto14 Var 'Pedido:'    SIZE 100,25 PIXEL
		oTexto14:oFont := TFont():New('Arial',,40,,.T.,,,,.T.,.F.)
		@ nLin, nCol2 MSGET oPedido VAR cPedBip  SIZE 100,23 WHEN .F. PIXEL
		oPedido:oFont := TFont():New('Courier New',,50,,.T.,,,,.T.,.F.)

		// Total de Itens
		@ nLin,nCol1+510 SAY oTotCaixa Var "TOTAL DE ITENS" SIZE 100,10 PIXEL 
		@ nLin+15,nCol1+510 MSGET oGetBloqueio VAR nTotBloqueio SIZE 140,30 WHEN .F. PIXEL
		oTotCaixa:oFont := TFont():New('Arial',,27,,.T.,,,,.T.,.F.)
		oGetBloqueio:oFont := TFont():New('Arial',,70,,.T.,,,,.T.,.F.)
		nLin += 15                                       

		// Informações do Produto
		@ nLin+15, nCol1	SAY oTexto10 Var 'Produto:'    SIZE 100,25 PIXEL
		oTexto10:oFont := TFont():New('Arial',,40,,.T.,,,,.T.,.F.)
		@ nLin+15, nCol2 MSGET oProduto VAR cProdBip  SIZE 200,23 WHEN .F. PIXEL
		oProduto:oFont := TFont():New('Courier New',,50,,.T.,,,,.T.,.F.)
		nLin += 15                                       

		@ nLin+27, nCol2 MSGET oDescricao VAR cDescBip  SIZE 400,22 WHEN .F. PIXEL
		oDescricao:oFont := TFont():New('Courier New',,50,,.T.,,,,.T.,.F.)
		nLin += 15                    

		@ nLin+45, nCol2     BITMAP   oBmp1 RESNAME "BR_VERDE"  		SIZE 35,15 NOBORDER WHEN .F. PIXEL																
		@ nLin+45, nCol2+10  BITMAP   oBmp2 RESNAME "BR_VERMELHO"	SIZE 35,15 NOBORDER WHEN .F. PIXEL																
		@ nLin+45, nCol2+20  SAY "Coleta não realizada" SIZE 100,10 PIXEL																
		@ nLin+45, nCol2+115 BITMAP   oBmp3 RESNAME "BR_VERDE"  		SIZE 35,15 NOBORDER WHEN .F. PIXEL
		@ nLin+45, nCol2+125 BITMAP   oBmp4 RESNAME "BR_AZUL"			SIZE 35,15 NOBORDER WHEN .F. PIXEL																
		@ nLin+45, nCol2+135 SAY "Coleta Pendente" SIZE 100,10 PIXEL																
		@ nLin+45, nCol2+215 BITMAP   oBmp5 RESNAME "BR_VERDE"  		SIZE 35,15 NOBORDER WHEN .F. PIXEL
		@ nLin+45, nCol2+225 BITMAP   oBmp6 RESNAME "BR_VERDE"		SIZE 35,15 NOBORDER WHEN .F. PIXEL																
		@ nLin+45, nCol2+235 SAY "Coleta finalizada" SIZE 100,10 PIXEL

		// Total Coletado
		@ nLin+10, nCol1+510 SAY oTotColeta Var "TOTAL COLETADO" SIZE 100,10 PIXEL
		@ nLin+25, nCol1+510 MSGET oGetColeta VAR nTotColeta SIZE 140,30 WHEN .F. PIXEL
		oTotColeta:oFont := TFont():New('Arial',,27,,.T.,,,,.T.,.F.)
		oGetColeta:oFont := TFont():New('Arial',,70,,.T.,,,,.T.,.F.)

		// Total a Coletar (Restante)
		@ nLin+65, nCol1+510 SAY oTotResto Var "RESTAM" SIZE 100,10 PIXEL
		@ nLin+80, nCol1+510 MSGET oGetResto VAR nResto SIZE 140,30 WHEN .F. COLOR CLR_RED PIXEL
		oTotResto:oFont := TFont():New('Arial',,27,,.T.,,,,.T.,.F.)
		oGetResto:oFont := TFont():New('Arial',,70,,.T.,,,,.T.,.F.)
		
		// Status do Pedido
		@ nLin+120, nCol1+510 SAY oTotSld Var "SITUAÇÃO DO PEDIDO" SIZE 150,10 PIXEL
		oTotSld:oFont := TFont():New('Arial',,27,,.T.,,,,.T.,.F.)
		@ nLin+135,nCol1+510 MSGET oTotOK  Var cSitPedido SIZE 140,30 WHEN .F. COLOR CLR_RED PIXEL
		oTotOK:oFont := TFont():New('Arial',,060,,.T.,,,,.T.,.F.)
		nLin += 60
		
		// Leitura da Etiqueta
		@ nLin-02, nCol1-05 TO  nLin+40,nCol1+495 LABEL " Código de Barras "  OF oDlg01 PIXEL
		@ nLin+15, nCol1	  SAY oTexto1 Var 'Etiqueta:'    SIZE 100,30 PIXEL
		oTexto1:oFont := TFont():New('Arial',,35,,.T.,,,,.T.,.F.)
		@ nLin+08, nCol2 MSGET oEtiqueta VAR cEtiqueta  SIZE 250,25 WHEN .T. Valid ValidaEtiq() PIXEL
		oEtiqueta:oFont := TFont():New('Courier New',,50,,.T.,,,,.T.,.F.)
		nLin -= 10

		aFields := { " ", " ", "Etiqueta", "Produto", "Descricao", "Item", "Quantidade", "Qtde. Lida", "RECNO" }
		oSeparar := TWBrowse():New( nLin+55, nCol1-05, nLin+392, nCol1+120,,aFields,,oDlg01,,,,,,,,,,,,.F.,,.T.,,.F.,,,)//##"Empresa"//##"Empresa"
		oSeparar:SetArray(aItemBloq)
		oSeparar:bLine      := { || { If( !aItemBloq[oSeparar:nAT,1], oOk, oNOK ), fSemaCol(aItemBloq[oSeparar:nAT,7], aItemBloq[oSeparar:nAT,8]), aItemBloq[oSeparar:nAt,3], aItemBloq[oSeparar:nAT,4], aItemBloq[oSeparar:nAT,5], aItemBloq[oSeparar:nAT,6], aItemBloq[oSeparar:nAT,7], aItemBloq[oSeparar:nAT,8], aItemBloq[oSeparar:nAT,9] } }

		// Status dos itens do pedido
		If !fMontaExp(SC5->C5_NUM)
			oDlg01:End()		
			Exit
		EndIf 

		nLin += 165
		
		// Botões de controle
		@ nLin-35, nCol1+510 BUTTON oEntregar PROMPT "Libera o Faturamento"  ACTION EVAL( {|| If(nResto == 0 .Or. SC5->C5_XSEPARA=="O", U_RFATM06(), .T.), oDlg01:End() } ) SIZE 140,25 PIXEL OF oDlg01
		@ nLin-08, nCol1+510 BUTTON oSair     PROMPT "Sair"              		ACTION EVAL( {|| lSair := .T., oDlg01:End() } ) SIZE 140,25 PIXEL OF oDlg01
		
		If nResto == 0 .Or. SC5->C5_XSEPARA == "O"
			oEtiqueta:Disable()
			oEntregar:Enable()
		Else
			oEtiqueta:Enable()
			oEntregar:Disable()
		Endif 

		// Ativa a tela de controle
		oEntregar:Refresh()
		ACTIVATE MSDIALOG oDlg01 CENTER

		If lSair
			Exit
		Endif 

		// Reinicia as variáveis
		cSitPedido 	:= Space(08)
		nTotBloqueio:= 0		
		nSaldoBip   := 0
		nTotColeta  := 0
		nResto 		:= 0
		nLin      	:= 15
		nCol1     	:= 10
		nCol2     	:= 95
		
	EndDo
	
Return

/*/{Protheus.doc} RFATM06
Conclui a separação do pedido e libera faturamento

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

User Function RFATM06()

	LOCAL lResp    	:= .F. 
	Local nLargBtn 	:= 50
   Local nPeso    	:= 0
   Local nVol     	:= 0
	Local cEspecie		:= Space(TamSX3("C5_ESPECI1")[1])
   Local cMsg     	:= ""
	LOCAL cMensagem 	:= ""

	//Objetos e componentes
	LOCAL oDlgCompl
	LOCAL oFwLayer

	//Cabeçalho
	LOCAL oSayModulo, cSayModulo := 'FAT'
	LOCAL oSayTitulo, cSayTitulo := 'Liberação para faturamento'
	LOCAL oSaySubTit, cSaySubTit := 'Digite os campos complementares'

	//Tamanho da janela
	LOCAL nJanLarg := 550
	LOCAL nJanAltu := 480

	//Fontes
	LOCAL cFontUti    := "Tahoma"
	LOCAL oFontMod    := TFont():New(cFontUti, , -38)
	LOCAL oFontSub    := TFont():New(cFontUti, , -20)
	LOCAL oFontSubN   := TFont():New(cFontUti, , -20, , .T.)
	LOCAL oFontBtn    := TFont():New(cFontUti, , -14)
	LOCAL oFontSay    := TFont():New(cFontUti, , -12, , .T.)

	//Cria a janela
	DEFINE MSDIALOG oDlgCompl TITLE "Separação de Pedidos"  FROM 0, 0 TO nJanAltu, nJanLarg PIXEL

	//Criando a camada
	oFwLayer := FwLayer():New()
	oFwLayer:init(oDlgCompl,.F.)

	//Adicionando 3 linhas, a de título, a superior e a do calendário
	oFWLayer:addLine("TIT", 15, .F.)
	oFWLayer:addLine("COR", 85, .F.)

	//Adicionando as colunas das linhas
	oFWLayer:addCollumn("HEADERTEXT",   090, .T., "TIT")
	oFWLayer:addCollumn("BTNSAIR",      010, .T., "TIT")
	oFWLayer:addCollumn("COLMEMO",      100, .T., "COR")

	//Criando os paineis
	oPanHeader := oFWLayer:GetColPanel("HEADERTEXT", "TIT")
	oPanSair   := oFWLayer:GetColPanel("BTNSAIR",    "TIT")
	oPanMemo   := oFWLayer:GetColPanel("COLMEMO",    "COR")

	//Títulos e SubTítulos
	oSayModulo := TSay():New(004, 003, {|| cSayModulo}, oPanHeader, "", oFontMod,  , , , .T., RGB(149, 179, 215), , 200, 30, , , , , , .F., , )
	oSayTitulo := TSay():New(004, 045, {|| cSayTitulo}, oPanHeader, "", oFontSub,  , , , .T., RGB(031, 073, 125), , 200, 30, , , , , , .F., , )
	oSaySubTit := TSay():New(014, 045, {|| cSaySubTit}, oPanHeader, "", oFontSubN, , , , .T., RGB(031, 073, 125), , 750, 50, , , , , , .F., , )

	// Campos editáveis
	oSayPeso := TSay():New( 003, 010,{|| "Peso Bruto"},oPanMemo,,oFontSay,.F.,.F.,.F.,.T.,,,,,.F.,.F.,.F.,.F.,.F.)
	oGetPeso := TGet():New( 001, 050,{|u| If(PCount() > 0,nPeso := u,nPeso)},oPanMemo,060,,'999,999.99',{|| .T. },,,,.T.,,.T.,,.F.,{|| .T.},.F.,.F., ,.F.,.F.,,"nPeso",,,,)
	oSayVol  := TSay():New( 016, 010,{|| "Volume "},oPanMemo,,oFontSay,.F.,.F.,.F.,.T.,,,,,.F.,.F.,.F.,.F.,.F.)
	oGetVol  := TGet():New( 014, 050,{|u| If(PCount() > 0,nVol := u,nVol)},oPanMemo,060,,'999999',{|| .T. },,,,.T.,,.T.,,.F.,{|| .T.},.F.,.F., ,.F.,.F.,,"nVol",,,,)
	oSayEspe := TSay():New( 036, 010,{|| "Especie "},oPanMemo,,oFontSay,.F.,.F.,.F.,.T.,,,,,.F.,.F.,.F.,.F.,.F.)
	oGetEspe := TGet():New( 034, 050,{|u| If(PCount() > 0,cEspecie := u,cEspecie)},oPanMemo,080,,'@!',{|| .T. },,,,.T.,,.T.,,.F.,{|| .T.},.F.,.F., ,.F.,.F.,,"cEspecie",,,,)
   oSayMsg  := TSay():New( 052, 010,{|| "Observações "},oPanMemo,,oFontSay,.F.,.F.,.F.,.T.,,,,,.F.,.F.,.F.,.F.,.F.)
	oGetMemo := TMultiGet():New(062,010,{|u|if(Pcount()>0,cMsg:=u,cMsg)},oPanMemo,250,100,,,,,,.T.)

   //Criando os botões
	@ 168,010 TO 169,260 OF oPanMemo PIXEL
	oBtnSair := TButton():New(173, 155, "Liberar", oPanMemo,  {|| lResp := .T., oDlgCompl:End()}, nLargBtn, 018, , oFontBtn, , .T., , , , , , )
	oBtnCanc := TButton():New(173, 210, "Cancelar", oPanMemo, {|| lResp := .F., oDlgCompl:End()}, nLargBtn, 018, , oFontBtn, , .T., , , , , , )
	
	ACTIVATE MSDIALOG oDlgCompl CENTERED

	If lResp

		BEGIN TRANSACTION 

		   If !Reclock("SC5",.F.)
				lResp := .F.
				DisarmTransaction()
				Break
			Endif 

			SC9->(dbSetOrder(1))
			SC9->(dbSeek(SC5->C5_FILIAL+SC5->C5_NUM))
			While SC9->(!Eof()) .And. SC9->C9_FILIAL+SC9->C9_PEDIDO == SC5->C5_FILIAL+SC5->C5_NUM
				If !Reclock("SC9",.F.)
				   lResp := .F.
					DisarmTransaction()
					Break
				EndIf 
				SC9->C9_BLWMS := Space(TamSX3("C9_BLWMS")[1])
				SC9->(MsUnlock())
				SC9->(dbSkip())
			End

			// Coloca o pedido em espera de faturamento
			SC5->C5_XSEPARA := "S"
			SC5->C5_VOLUME1 := nVol
			SC5->C5_PESOL   := nPeso
			SC5->C5_PBRUTO  := nPeso
			SC5->C5_ESPECI1 := cEspecie
			SC5->C5_OBSEXP  := cMsg
			SC5->(MsUnlock())

		END TRANSACTION 

		cMensagem := IIF(!lResp,"Pedido "+SC5->C5_NUM+" está bloqueado por outro usuário. Aguarde um instante e tente novamente.",;
										"Pedido "+SC5->C5_NUM+" colocado em espera para faturamento com sucesso! ")
		ApMsgStop(cMensagem)

		If lResp
			lSair := .T.
		EndIf 

	EndIf 

Return 

/*/{Protheus.doc} RFATM04
Estorno da Separação

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

User Function RFATM04()

	LOCAL lMsg := ApMsgYesNo("Deseja estornar a separação do pedido "+SC5->C5_NUM+"?")
	LOCAL lRet := .T. 

	If lMsg 
		
		BEGIN TRANSACTION 

		   If !Reclock("SC5",.F.)
				lResp := .F.
				DisarmTransaction()
				Break
			Endif 

			SC9->(dbSetOrder(1))
			SC9->(dbSeek(SC5->C5_FILIAL+SC5->C5_NUM))
			While SC9->(!Eof()) .And. SC9->C9_FILIAL+SC9->C9_PEDIDO == SC5->C5_FILIAL+SC5->C5_NUM
				If !Reclock("SC9",.F.)
				   lRet := .F.
					DisarmTransaction()
					Break
				EndIf 
				SC9->C9_XQTCON := 0
				SC9->C9_BLWMS  := "03"
				SC9->(MsUnlock())
				SC9->(dbSkip())
			End

			// Coloca o pedido em espera de faturamento
			SC5->C5_XSEPARA := "N"
			SC5->C5_VOLUME1 := 0
			SC5->C5_ESPECI1 := ""
			SC5->C5_OBSEXP  := ""
			SC5->(MsUnlock())

		END TRANSACTION 
		
		If !lRet 
			ApMsgAlert("Pedido "+SC5->C5_NUM+" está bloqueado por outro usuário. Aguarde um instante e tente novamente.")
		Else 
			ApMsgAlert("Separação do Pedido "+SC5->C5_NUM+" estornada com sucesso. O pedido está disponível para uma nova coleta de separação.")
		EndIf 

	EndIf 

Return lRet

/*/{Protheus.doc} RFATM05
Visualiza o Pedido de Venda

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

User Function RFATM05()

	LOCAL aAreaTMP := SC5->(GetArea())
	LOCAL aAreax   := { aAreaTMP, GetArea() }

	PRIVATE cCadastro := "Pedido de venda"
	PRIVATE aRotina := {	{ "Pesquisar" ,'AxPesqui'  ,0,1},; 	//'Pesquisar'
								{ "Visualizar",'A410Visual',0,2} } 	//'Visualizar'

	A410Visual("SC5",SC5->(Recno()),2)
	AEVal(aAreax, { |x| RestArea(X)} )

Return

/*/{Protheus.doc} ValidaEtiq
Valida a etiqueta lida

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

Static Function ValidaEtiq(lTeste)

LOCAL 	lColeta 	:= .T.
DEFAULT 	lTeste 	:= .F.

If !Empty(cEtiqueta)

	// Verifica etiqueta bipada
	If Len(AllTrim(cEtiqueta)) >= 13 
		
		SB1->( dbSetOrder(5) )
		If !SB1->(dbSeek(xFilial()+SubStr(cEtiqueta,1,13)))
			SB1->( dbSetOrder(1) )
			If !SB1->(dbSeek(xFilial()+PADR(cEtiqueta,TamSX3("B1_COD")[1])))
				ApMsgAlert("Produto não encontrado para esse código de barras.")
				cEtiqueta := Space(_nTamEtiq)
				oEtiqueta:Refresh()
				oEtiqueta:SetFocus()
				Return ( .F. )
			EndIf 

		EndIf 

		// Atualiza a coleta do item
		lColeta := fAtuColeta( SB1->B1_COD )
		If !lColeta
			cEtiqueta := Space(_nTamEtiq)
			oEtiqueta:Refresh()
			oEtiqueta:SetFocus()
			Return ( .F.)
		EndIf 

		// Atualiza Tela
		cProdBip  := SB1->B1_COD
		cDescBip  := SB1->B1_DESC
		oProduto:Refresh()
		oDescricao:Refresh()
		oPedido:Refresh()
	
	Else

		SB1->(dbSetOrder(1))
		If !SB1->(dbSeek(xFilial()+PADR(cEtiqueta,TamSX3("B1_COD")[1])))
			ApMsgAlert("Produto não encontrado para esse código de barras.")
			cEtiqueta := Space(_nTamEtiq)
			oEtiqueta:Refresh()
			oEtiqueta:SetFocus()
			Return ( .F. )
		EndIf 

		If SB1->B1_XCOLETA == "S"
			ApMsgAlert("Esse produto não permite digitação. Realize o trabalho pelo coletor.")
			cEtiqueta := Space(_nTamEtiq)
			oEtiqueta:Refresh()
			oEtiqueta:SetFocus()
			Return ( .F. )
		EndIf 

		// Atualiza a coleta do item
		lColeta := fAtuColeta( SB1->B1_COD )
		If !lColeta
			cEtiqueta := Space(_nTamEtiq)
			oEtiqueta:Refresh()
			oEtiqueta:SetFocus()
			Return ( .F.)
		EndIf 

		// Atualiza Tela
		cProdBip  := SB1->B1_COD
		cDescBip  := SB1->B1_DESC
		oProduto:Refresh()
		oDescricao:Refresh()
		oPedido:Refresh()

	EndIf

	cEtiqueta := Space(_nTamEtiq)
	oEtiqueta:Refresh()
	oEtiqueta:SetFocus()

	If nTotColeta == nTotBloqueio
	
		Reclock("SC5",.F.)
		SC5->C5_XSEPARA := "O"
		SC5->(MsUnlock())
		cSitPedido 	:= "OK"
		nResto 		:= 0
		oEntregar:Enable()
		oEntregar:Refresh()
		oGetResto:Refresh()
		oTotOk:Refresh()
		
	EndIf
			
EndIf

Return

/*/{Protheus.doc} fMontaExp
Monta o browse com a situação dos itens em coleta

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

Static Function fMontaExp(cPedUso)

	LOCAL cDescB1 := ""
	LOCAL cQuery  := ""
	LOCAL lRet    := .T.

	aItemBloq := {}
	cQuery := "SELECT C9_FILIAL, C9_PEDIDO, C9_ITEM, C9_PRODUTO, C9_QTDLIB, C9_XQTCON, R_E_C_N_O_ SC9RECNO "
	cQuery += "FROM " + RetSqlName("SC9") + " (NOLOCK) SC9 "
	cQuery += "WHERE C9_FILIAL = '"+xFilial("SC9")+"' AND "
	cQuery += "C9_PEDIDO = '"+cPedUso+"' AND "
	cQuery += "C9_NFISCAL = '' AND "
	//cQuery += "C9_BLWMS ='03' AND "
	cQuery += "D_E_L_E_T_=''"
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TEMP",.F.,.T.)

	If TEMP->(Eof())
		ApMsgAlert("Não foram encontrados os registros de liberação desse pedido. Verifique o pedido e tente novamente.")
		lRet := .F.
	EndIf 

	Do While TEMP->(!Eof()) .And. lRet
	   cDescB1 := Posicione("SB1",1,xFilial("SB1")+TEMP->C9_PRODUTO,"B1_DESC")
		Aadd(aItemBloq, { .T., fSemaCol(TEMP->C9_QTDLIB, TEMP->C9_XQTCON), TEMP->C9_PEDIDO, TEMP->C9_PRODUTO, cDescB1, TEMP->C9_ITEM, TEMP->C9_QTDLIB, TEMP->C9_XQTCON, TEMP->SC9RECNO } )
		nTotBloqueio += TEMP->C9_QTDLIB
		nSaldoBip    += TEMP->C9_XQTCON
		TEMP->(dbSkip())
	EndDo                

	TEMP->(dbCloseArea())

	If lRet
		nTotColeta  := nSaldoBip
		nResto 		:= nTotBloqueio - nSaldoBip
		cSitPedido 	:= IIF(nResto == 0,"OK","PENDENTE")
		Reclock("SC5",.F.)
		If cSitPedido == "OK"
			SC5->C5_XSEPARA := "O"
		ElseIf cSitPedido == "PENDENTE" .And. nSaldoBip == 0
			SC5->C5_XSEPARA := "N"
		ElseIf cSitPedido == "PENDENTE" .And. nSaldoBip > 0
			SC5->C5_XSEPARA := "P"
		Else
			SC5->(MsUnlock())
		EndIf 
		oGetBloqueio:Refresh()
		oGetResto:Refresh()
		oGetColeta:Refresh()	
		oTotOK:Refresh()
		oSeparar:SetArray(aItemBloq)
		oSeparar:bLine := { || { If( aItemBloq[oSeparar:nAT,1], oOk, oNOK ), aItemBloq[oSeparar:nAt,2], aItemBloq[oSeparar:nAt,3], aItemBloq[oSeparar:nAT,4], aItemBloq[oSeparar:nAT,5], aItemBloq[oSeparar:nAT,6], aItemBloq[oSeparar:nAT,7], aItemBloq[oSeparar:nAT,8], aItemBloq[oSeparar:nAT,9] } }
		oSeparar:Refresh()
	EndIf 

Return ( lRet )

/*/{Protheus.doc} fAtuColeta
Atualiza a coleta de dados

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

Static Function fAtuColeta( cEtqColeta, nRegSC9 )

	LOCAL _nPosEtq 	:= aScan(aFields,{|x| AllTrim(x) == "Produto"})
	LOCAL _nPosLib 	:= aScan(aFields,{|x| AllTrim(x) == "Quantidade"})	
	LOCAL _nPosCol 	:= aScan(aFields,{|x| AllTrim(x) == "Qtde. Lida"})
	LOCAL _nPosRec 	:= aScan(aFields,{|x| AllTrim(x) == "RECNO"})
	LOCAL aColeta     := {}
	LOCAL nQ				:= 0
	LOCAL lRetCol     := .T. 
	LOCAL lEtqOK      := .F.
	LOCAL lTotalCol   := .F. 

	DEFAULT cCodMaster := "N"

	For nQ := 1 to Len(aItemBloq)

		If aItemBloq[nQ,_nPosEtq] == cEtqColeta

			// Posiciona no Item coletado 
			oSeparar:nAt := nQ
			lEtqOK		 := .T.

			// Ignora item totalmente coletado
			If aItemBloq[nQ,_nPosLib] == aItemBloq[nQ,_nPosCol]
			   lTotalCol := .T.
			   Loop 
			EndIf 

			// Atualiza coleta
			aColeta := fAtuSC9(aItemBloq[oSeparar:nAt,_nPosRec], aItemBloq[nQ,_nPosLib], SB1->B1_XMASTER)
			If !aColeta[2]
			   lRetCol := aColeta[2]
			   Exit 
			Endif 

			// Atualiza tela
			aItemBloq[nQ,_nPosCol]    := aColeta[1]
			aItemBloq[oSeparar:nAt,2] := fSemaCol(aItemBloq[nQ,_nPosLib],aItemBloq[nQ,_nPosCol])
			oSeparar:SetArray(aItemBloq)
			oSeparar:bLine := { || { If( aItemBloq[oSeparar:nAT,1], oOk, oNOK ), aItemBloq[oSeparar:nAt,2], aItemBloq[oSeparar:nAt,3], aItemBloq[oSeparar:nAT,4], aItemBloq[oSeparar:nAT,5], aItemBloq[oSeparar:nAT,6], aItemBloq[oSeparar:nAT,7], aItemBloq[oSeparar:nAT,8], aItemBloq[oSeparar:nAT,9] } }
			oSeparar:nRowPos := _nPosEtq
			oSeparar:Refresh()
			Exit

		EndIf 

	Next 

	If lTotalCol
		ApMsgAlert("Quantidade coletada é maior do que a quantidade liberada.")
		lRetCol := .F.
	EndIf
	
	IF !lEtqOK
		ApMsgStop("A etiqueta não pertence a um produto desse pedido. Verifique o item e tente novamente.")
		lRetCol := .F.
	EndIf 

Return ( lRetCol )

/*/{Protheus.doc} aAtuSC9
Atualiza a quantidade coletada

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

Static Function fAtuSC9(nRecUso, nQtdeLib, cCodMst)

	Local aRet := {}

	SC9->(dbSetOrder(1))
	SC9->(dbGoto(nRecUso))

	If cCodMst == "S"
		Reclock("SC9",.F.)
		SC9->C9_XQTCON := SC9->C9_QTDLIB
		SC9->(MsUnlock())
		Reclock("SC5",.F.)
		SC5->C5_XSEPARA := "P"
		SC5->(MsUnlock())
		AADD(aRet, SC9->C9_XQTCON)
		AADD(aRet, .T. )
		nTotColeta += SC9->C9_QTDLIB
		nResto -= SC9->C9_QTDLIB
		oGetResto:Refresh()
		oGetColeta:Refresh()	
		Return( aRet )
	EndIf 

	If (SC9->C9_XQTCON + 1) > nQtdeLib
		ApMsgAlert("Quantidade coletada é maior do que a quantidade liberada.")
		AADD(aRet, SC9->C9_XQTCON)
		AADD(aRet, .F. )
	Else 
		Reclock("SC9",.F.)
		SC9->C9_XQTCON := SC9->C9_XQTCON + 1
		SC9->(MsUnlock())
		Reclock("SC5",.F.)
		SC5->C5_XSEPARA := "P"
		SC5->(MsUnlock())
		AADD(aRet, SC9->C9_XQTCON)
		AADD(aRet, .T. )
		nTotColeta++
		nResto -= 1
		oGetResto:Refresh()
		oGetColeta:Refresh()	
	Endif 

Return ( aRet )

/*/{Protheus.doc} fSemaCol
Semáforo da coleta de dados

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

Static Function fSemaCol(nQtdeTotal, nQtdeLidas)

	LOCAL oObjSema 

	If nQtdeLidas == 0
	   oObjSema := oNOk
	ElseIf nQtdeLidas > 0 .And. nQtdeLidas < nQtdeTotal
		oObjSema := oPendente
	Else 
	   oObjSema := oOk
	EndIf 

Return ( oObjSema )

/*/{Protheus.doc} fVerBloq
Verifica Bloqueio do Pedido de Venda antes da separação

@type 	function
@author 	Diego
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

Static Function fVerBloq(cPedUso)

	LOCAL lRet 		:= .T.
	LOCAL lCredito := .F.
	LOCAL lEstoque := .F.

	If SC5->C5_XSEPARA == "S"
	   ApMsgInfo("Pedido aguardando faturamento. Para iniciar nova coleta, é necessário estornar a separação.")
		Return(.F.)
	EndIf 

	SC9->(dbSetOrder(1))
	SC9->(dbSeek(SC5->C5_FILIAL+SC5->C5_NUM))
	While SC9->(!Eof()) .And. SC9->C9_FILIAL+SC9->C9_PEDIDO == SC5->C5_FILIAL+SC5->C5_NUM
		If !Empty(SC9->C9_BLEST)
		   lRet 		:= .F. 
			lEstoque := .T.
		EndIf 
		If !Empty(SC9->C9_BLCRED)
		   lRet 		:= .F. 
			lCredito := .T.
		EndIf 
		SC9->(dbSkip())
	End

	If !lRet 
		If lCredito .And. lEstoque
			ApMsgStop("Separação não permitida. Esse pedido está com bloqueio de crédito e de estoque. Verifique.")
		ElseIf lCredito .And. !lEstoque 
			ApMsgStop("Separação não permitida. Esse pedido está com bloqueio de crédito. Verifique.")
		ElseIf !lCredito .And. lEstoque 			
			ApMsgStop("Separação não permitida. Esse pedido está com bloqueio de estoque. Verifique.")
		EndIf 
	EndIf 

Return ( lRet )
