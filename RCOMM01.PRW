#INCLUDE "PROTHEUS.CH"
#INCLUDE "ApWizard.ch"
#INCLUDE "Totvs.CH"

//Wizards
#DEFINE INTRODUCAO		1
#DEFINE PAR_RANGE	 		2
#DEFINE PAR_ARQ         3
#DEFINE PAR_PROC  		4
#DEFINE PAR_FINAL  		5

/*/{Protheus.doc} RCOMM02()
Importação de pedidos de compra 

@author  Michel Sander
@type    function
@since   25/07/2021
@version 1.0
@return  Nil
/*/

User Function RCOMM01()

   Local oWizard 	:= Nil
   Local nA		   := 0
   Local cPergEnt	:= "RCOMM01"

   //Objetos do Wizard 2
   Local aPRange	   := {}
   Local aRetRange	:= {}
   Local aCpoRange	:= {}

   //Fontes
   Local oFont16	   := TFont():New( "Arial",10,14,,.F.,,,,.T.,.F.)
   Local oFont16n 	:= TFont():New( "Arial",08,12,,.T.,,,,.T.,.F.)

   Private aTmpTabs	:= {}
   Private aMarks		:= {}
   Private aPanels	:= {}
   Private aIndexCab	:= {}
   Private oFolder, oGetMod 
   Private cMarca 		:= GetMark()	
   Private lPrim		:= .T.
   Private lErrorProc := .F.
   Private cTargetDir := ""
   Private cProcFInal := ""
   Private nRegua     := 0
   Private oRegua
   Private lMsErroAuto	:= .F.

   //Wizard 1: Introdução 
   DEFINE WIZARD oWizard TITLE "Inclusão de Pedido de Compra" ;
         HEADER "Importação de arquivo" ;  
         MESSAGE "Introdução" ; 
         TEXT "Esta rotina tem o objetivo de "+CRLF+;
               "importar automaticamente um pedido de compra "+CRLF+;
               "á partir de um arquivo .CSV escolhido pelo usuário."+CRLF; 
         NEXT {||.T.} ;
         FINISH {||.T.} ;
         PANEL

      //Wizard 2: Parâmetros
      CREATE PANEL oWizard;
            HEADER "Parâmetros";
            MESSAGE  "Selecione os parâmetros do PEDIDO DE COMPRA";	
            BACK {|| .T. };
            NEXT {|| RCOMM02() } ;
            FINISH {|| .T. };
            PANEL
      
      aPRange	   := {}
      aRetRange	:= {}
      aCpoRange	:= {}

      // Montagem do Parambox de selecao pro Range  
      aAdd(aPRange,{1,"Fornecedor",Space(TAMSX3("A2_COD")[1])	   ,"@!","","SA2"	,""	,06,.F.,"A2_COD"})
      aAdd(aPRange,{1,"Loja"		 ,Space(TAMSX3("A2_LOJA")[1])	   ,"@!","","SA2"	,""	,02,.F.,"A2_LOJA"})
      aAdd(aPRange,{1,"Cond. Pgto",Space(TAMSX3("C7_COND")[1])	   ,"@!","","SE4"	,""	,03,.F.,"C7_COND"})
      aAdd(aPRange,{1,"TES"		 ,Space(TAMSX3("C7_TES")[1])	   ,"@!","","SF4"	,""	,03,.F.,"C7_TES"})
                     
      For nA := 1 To Len(aPRange)
         aAdd(aRetRange,aPRange[nA][3])
         aAdd(aCpoRange,aPRange[nA][10])
         &("MV_PAR"+STRZERO(nA,2)) := aRetRange[nA] := ParamLoad(cPergEnt,aPRange,nA,aPRange[nA][3])	
      Next nA

      ParamBox(aPRange,"Parâmetros",@aRetRange,,,,,,oWizard:GetPanel(PAR_RANGE))

      //Wizard 3: Aviso
      CREATE PANEL oWizard ;
            HEADER "Arquivo CSV" ;
            MESSAGE "Arquivo selecionado:";
            BACK {|| .T. } ;
            NEXT {|| .T. } ;
            FINISH {|| .T. } ;
            PANEL   

      @ 004,010 SAY "Caminho do ARQUIVO:"       FONT oFont16n  SIZE 0150,20 OF oWizard:GetPanel(PAR_ARQ) PIXEL COLOR CLR_BLACK
      @ 012,010 SAY SubStr(cTargetDir,1,40)     FONT oFont16   SIZE 1000,20 OF oWizard:GetPanel(PAR_ARQ) PIXEL COLOR CLR_BLUE
      @ 019,010 SAY SubStr(cTargetDir,41,40)    FONT oFont16   SIZE 1000,20 OF oWizard:GetPanel(PAR_ARQ) PIXEL COLOR CLR_BLUE
      @ 026,010 SAY SubStr(cTargetDir,81,40)    FONT oFont16   SIZE 1000,20 OF oWizard:GetPanel(PAR_ARQ) PIXEL COLOR CLR_BLUE
      @ 033,010 SAY SubStr(cTargetDir,121,40)   FONT oFont16   SIZE 1000,20 OF oWizard:GetPanel(PAR_ARQ) PIXEL COLOR CLR_BLUE
      
      //Wizard 4: Processamento
      CREATE PANEL oWizard ;
            HEADER "Processamento"+CRLF+CRLF ;
            MESSAGE "Clique em Avançar para iniciar";
            BACK {|| .F. } ;
            NEXT {|| RCOMM03(@oRegua) } ;
            FINISH {|| .T. } ;
            PANEL   

      @ 10,010 SAY "Registro(s) Lido(s)"        SIZE 150,10 OF oWizard:GetPanel(PAR_PROC) PIXEL
      @ 20,010 METER oRegua VAR nRegua TOTAL 100 SIZE 215,10 OF oWizard:GetPanel(PAR_PROC) NOPERCENTAGE PIXEL

      //Wizard 5: Encerramento
      CREATE PANEL oWizard ;
            HEADER "Final de Processamento" ;
            MESSAGE "Leitura de Arquivo CSV";
            BACK {|| .F. } ;
            NEXT {|| .F. } ;
            FINISH {|| .T. } ;
            PANEL   

      @ 10,010 SAY cProcFinal SIZE 500,30 OF oWizard:GetPanel(PAR_FINAL) PIXEL

   oWizard:Activate()

   //Salva as perguntas
   For nA := 1 To Len(aRetRange)
      &("MV_PAR"+STRZERO(nA,2)) := aRetRange[nA]
   Next nA

   ParamSave(cPergEnt,aPRange,"1")

REturn 

/*/{Protheus.doc} RCOMM02()
Seleciona o arquivo CSV

@author  Diego
@type    function
@since   25/07/2021
@version 1.0
@return  Nil
/*/

Static Function RCOMM02()

   local cTempDir   := getTempPath()
   Local lOk        := .T.
   
   cTargetDir := TFileDialog( "Arquivos CSV (*.CSV) | Todos arquivos CSV (*.CSV) ",'Selecao de Arquivos',, cTempDir, .F.)

   If Empty(cTargetDir)
      ApMsgAlert("Nenhum arquivo foi escolhido. O processo será interrompido.")
      lOk := .F.
   EndIf 

Return ( lOk )

/*/{Protheus.doc} RCOMM03()
Prepara a leitura do arquivo CSV

@author  Diego
@type    function
@since   25/07/2021
@version 1.0
@return  Nil
/*/

Static Function RCOMM03(oRegua)

   Local cLinha      := ""
   Local nLinha      := 0
   Local nPercent    := 0

   Private bData      := {|cVar| Ctod(Transform(cVar, "@ER 99/99/9999"))}
   Private bNum       := {|cVar| Val(StrTran(Alltrim(cVar), ",", "."))}
   Private nRotinaAut := 3
   Private cAliasImp  := ""
   Private aFieldsCab := Nil
   Private aCabPos    := Nil
   Private cFieldsQue := Nil
   Private cFieldsLog := ""
   Private aPedCom  := {}

   If lMsErroAuto
      ApMsgAlert("Processamento com erro. Clique em CANCELAR e tente novamente.")      
      Return ( .T. )
   EndIf 

   // Array com os campos que precisam de validação no cabeçalho
   aFieldsCab := {}        // { "C7_FILIAL", "C7_NUM", "C7_COND" }
   cFieldsQue := "C7_NUM"

   SX3->(dbSetOrder(2)) // X3_CAMPO

	oRegua:Set(000)
	oRegua:Refresh()

	LeTxt(cTargetDir, {|cFile, cLinha, nLinha, nPercent| TrataImport(cFile, cLinha, nLinha, nPercent)}, oRegua)
	
	oRegua:Set(100)
	oRegua:Refresh()
	ProcessMessages()
	
	If aFieldsCab <> Nil
		CabItem()
	Endif

   SX3->(dbSetOrder(1)) // X3_ARQUIVO+X3_ORDEM

Return ( .T. )

/*/{Protheus.doc} LeTXT()
Processa a leitura do arquivo CSV

@author  Diego
@type    function
@since   25/07/2021
@version 1.0
@return  Nil
/*/

Static Function LeTXT(cFile, bBlock, oRegua)

   Local nBuf	   := 16 * 1024  // 16K
   Local nHdl	   := fOpen(cFile, 0)
   Local nTam	   := fSeek(nHdl, 0, 2)
   Local nLin	   := 0
   Local nLido    := 0
   Local nPos     := Nil
   Local cBuffer  := ""
   Local lLeuTudo := .F.
   Local cLinha   := ""
   Local nPercent := 0

   fSeek(nHdl, 0)
   While nLido < nTam
      If Len(cBuffer) < nBuf .And. ! lLeuTudo
         cBuffer  += fReadStr(nHdl, nBuf)
         lLeuTudo := fSeek(nHdl, 0, 1) = nTam
      Endif
      nPos     := At(Chr(13) + Chr(10), cBuffer)
      cLinha   := Substr(cBuffer, 1, nPos - 1)
      nLin     ++
      nLido    += Len(cLinha) + 2 // Assumo Chr(13)+Chr(10) no final da linha
      nPercent := Min(80, (nLido * 100 / nTam) + 1) + 20
      oRegua:Set(nPercent)
      SysRefresh()
      Eval(bBlock, cFile, cLinha, nLin, nPercent)
      If lErrorProc
         Return ( .F. )
      EndIf 
      cBuffer := Substr(cBuffer, nPos + 2)
   Enddo

   fClose(nHdl)

Return ( .T. )

/*/{Protheus.doc} TrataImport()
Trata as linhas e campos do arquivo CSV para importação

@author  Diego 
@type    function
@since   25/07/2021
@version 1.0
@return  Nil
/*/

Static Function TrataImport(cFile, cLinha, nLinha, nPercent)

   Static aFields
   Static aKey

   Local aAuto    := {}
   Local cField   := Nil
   Local uField   := Nil
   Local nLoop    := Nil
   Local nPos     := Nil
   Local aLinha   := {}

   Default aFields := Nil

   If Empty(cLinha)
      Return
   Endif

   lErrorProc := .F.
   cLinha := StrTran(cLinha, '"', '')

   If nLinha == 1
      aFields := {}
      aKey := {}
      cLinha  := Upper(StrTran(cLinha, " ", ""))
      If Right(cLinha, 1) # ";"
         cLinha += ";"
      Endif
      Do While (nPos := At(";", cLinha)) > 0
         cField := Substr(cLinha, 1, nPos - 1)
         cLinha := Substr(cLinha   , nPos + 1)
         If "PEDIDO" $ AllTrim(Upper(cField)) 
            cField := "C7_NUM"
         ElseIf "PRODUTO" $ AllTrim(Upper(cField)) 
            cField := "C7_PRODUTO"
         ElseIf "QUANT" $ AllTrim(Upper(cField))
            cField := "C7_QUANT"
         ElseIf "VALOR" $ AllTrim(Upper(cField))
            cField := "C7_PRECO"
         ElseIf "TOTAL" $ AllTrim(Upper(cField))
            cField := "C7_TOTAL"
         ElseIf "CONTAINER" $ AllTrim(Upper(cField))
            cField := "C7_XLOTE"
         ElseIf "SERIAL" $ AllTrim(Upper(cField))
            cField := "C7_XSERIE"
         Else 
            cField := ""
         EndIf 
         If Empty(cField)
            Loop
         EndIf 
         If !SX3->(dbSeek(cField))
            ApMsgAlert("Campo: "+cField + " não encontrado no dicionário de dados.")
            cProcFinal := "Campo: "+cField + " não encontrado no dicionário de dados."+CRLF+;
                                   " Processamento com erros. Verifique sua planilha e tente novamente."
            lErrorProc := .T.
            Exit
         Endif
         Aadd(aFields, {cField, SX3->X3_TIPO, SX3->X3_TAMANHO})
         cFieldsLog += cField
      Enddo

      If lErrorProc
         Return ( lErrorProc )
      EndIf 

      If aFieldsCab # Nil
         aCabPos := {}
         For nLoop := 1 to Len(aFieldsCab)
            If (nPos := aScan(aFields, {|z| z[1] == aFieldsCab[nLoop]})) > 0
               Aadd(aCabPos, nPos)
            Else
               ApMsgAlert("Erro campo " + aFieldsCab[nLoop] + " não existente no cabecalho")
               cProcFinal := "Erro campo " + aFieldsCab[nLoop] + " nao existente no cabecalho"+CRLF+;
                             "Processamento com erros. Verifique sua planilha e tente novamente."
               lErrorProc := .T.
            Endif
         Next
      Endif
      Return ( lErrorProc )
   Endif

   If lErrorProc
      Return ( lErrorProc )
   EndIf 

   cLinha := '{"' +  StrTran( StrTran(cLinha, ";", '", "') , "Ç", "C")  + '"}'
   aLinha := &(cLinha)

   If Len(aLinha) # Len(aFields)
      ApMsgInfo("Tamanho da linha detalhe (" + Alltrim(Str(Len(aLinha))) + ") diferente da linha cabeçalho (" + Alltrim(Str(Len(aFields))) + ") Linha: " + Alltrim(Str(nLinha)))
      cProcFinal := "Tamanho da linha detalhe (" + Alltrim(Str(Len(aLinha))) + ") diferente da linha cabeçalho (" + Alltrim(Str(Len(aFields))) + ") Linha: " + Alltrim(Str(nLinha))+CRLF+;
                     "Processamento com erros. Verifique sua planilha e tente novamente."
      lErrorProc := .T.
      Return ( lErrorProc )
   EndIf 

   For nLoop := 1 to Len(aLinha) 
      uField := aLinha[nLoop]
      If aFields[nLoop, 2] == "D"
         uField := Eval(bData, uField)
      ElseIf aFields[nLoop, 2] == "N"
         uField := Eval(bNum, uField)
      ElseIf aFields[nLoop, 2] == "C"
         uField := AllTrim(PadR(aLinha[nLoop],aFields[nLoop, 3]))
         uField := A140IRemASC(uField) //-- NoAcento(Ansitooem(uField))
      Endif
      Aadd(aAuto, {aFields[nLoop, 1], uField, Nil})
   Next nLoop

   CabItem(aAuto)
   DbCommitAll()

Return(.T.)

/*/{Protheus.doc} CabItem()
Monta o cabeçalho e item do SC7 para processamento do MSExecAuto()

@author  Diego
@type    function
@since   25/07/2021
@version 1.0
@return  Nil
/*/

Static Function CabItem(aAuto)

   Static aCabItem
   Local nLoop      := Nil
   Local nPosAuto   := Nil
   Local nPos       := Nil
   Local nX          := 0
   Local nQ         := 0
   Local aCabec      := {}
   Local aItens      := {}
   Local aItensVg    := {}
   Local lRet        := .T.
   
   default aCabItem  := {}

   If aAuto # Nil
      nPosAuto := aScan(aAuto     , {|z| z[1] == cFieldsQue})
      If (nPos := aScan(aCabItem, {|z| z[1] == aAuto[nPosAuto, 2]})) == 0
         Aadd(aCabItem, {aAuto[nPosAuto, 2], {}, {}})
         nPos := Len(aCabItem)
         For nLoop := 1 to Len(aCabPos)
            Aadd(aCabItem[nPos, 2], {aFieldsCab[nLoop], aAuto[aCabPos[nLoop], 2], Nil})
         Next
      Endif
      Aadd(aCabItem[nPos, 3], {})

      For nLoop := 1 to Len(aAuto)
         If aScan(aFieldsCab, {|z| z == aAuto[nLoop, 1]}) == 0
            Aadd(Atail(aCabItem[nPos, 3]), aAuto[nLoop])
         Endif
      Next
   Endif

   If Len(aCabItem) > 1 .Or. (Len(aCabItem) > 0 .And. aAuto == Nil)

      //Inclusão do pedido de compras
      BEGIN TRANSACTION

         aadd(aCabec,{"C7_NUM" 		, GetSx8Num("SC7")	})
         aadd(aCabec,{"C7_EMISSAO"	, dDataBase				})
         aadd(aCabec,{"C7_FORNECE"	, MV_PAR01				})
         aadd(aCabec,{"C7_LOJA" 		, MV_PAR02				})
         aadd(aCabec,{"C7_COND" 		, MV_PAR03				})
         aadd(aCabec,{"C7_CONTATO" 	, " "					})
         aadd(aCabec,{"C7_FILENT" 	, cFilAnt				})

         aItens := AClone(aCabItem[1,3])
         For nQ := 1 to Len(aItens)
            aDadosItens := aClone(aItens[nQ])
            aLinha := {}
            cC7Item := StrZero(nQ,TamSX3("C7_ITEM")[1])
            aAdd(aLinha,{"C7_ITEM", cC7Item, Nil})
            For nX := 1 to Len(aDadosItens)
               If AllTrim(aDadosItens[nX,1]) == "C7_NUM"
                  Loop 
               Endif 
               aadd(aLinha,{aDadosItens[nX,1] , aDadosItens[nX,2]	,Nil})
            Next
            aAdd(aLinha,{"C7_TES", MV_PAR04, Nil})
            aAdd(aItensVg,aLinha)            
         Next

         // Inclui o pedido de compra
         lMsErroAuto := .F.
         aItensVg := FwVetByDic( aItensVg, "SC7", .T.)
         FWMsgRun(, { || MATA120(1, aCabec, aItensVg, 3, .F.) }, "MATA120", "Importando PEDIDO DE COMPRA..." )

         If lMsErroAuto
            MostraErro()
            lRet := .F.
         EndIf 
            
         If lRet
            ConfirmSX8()
            cProcFinal := "Importação Realizada COM SUCESSO."+CRLF+CRLF
            cProcFinal += "Número do Pedido gerado: "+SC7->C7_NUM
         Else 
            cProcFinal := "Processamento com erros. Verifique sua planilha e tente novamente."
            DisarmTransaction()
            Break
         Endif 

      END TRANSACTION

      aDel(aCabItem, 1)
      aSize(aCabItem, Len(aCabItem) - 1)

   Endif

Return ( lRet )
