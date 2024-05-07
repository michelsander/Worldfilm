#include "RwMake.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"
#Include "Protheus.ch"

/*/{Protheus.doc} xImpEti
Função para impressao de etiqueta por OP

@type 	function
@author 	Cristiano
@since 	30/06/2022
@Updated Michel Sander 
@Date 	11/07/2022
@version 1.0
@example
u_xImpEti()
/*/

User Function xImpEti()

	Local aArea     := GetArea()
	Local aPergs    := {}
	Local _aVet     := {}
	Local cOPDe     := ""
	Local cOPAt     := ""
	Local nQuant    := 1
	Local cQuery    := ""
	Local nLoop     := 1

	Private _nQtdEti := 0
	Private lPrint  := .F.

	While nLoop == 1

		aPergs := {}
		_aVet  := {}
		nQuant := 1
		cOPDe  := Space(TamSX3('C2_NUM')[01])
		cOPAt  := Space(TamSX3('C2_NUM')[01])
		aAdd(aPergs, {1, "OP De",  cOPDe,  "", ".T.", "SC2", ".T.", 80,  .F.})
		aAdd(aPergs, {1, "OP Ate", cOPAt,  "", ".T.", "SC2", ".T.", 80,  .T.})
		aAdd(aPergs, {1, "Qtde Etiquetas",nQuant,"@E 9,999","Positivo()", "",".T.", 80,.F.})

		If ParamBox(aPergs, "Informe os parametros para impressao da(s) etiqueta(s)")

			_nQtdEti := MV_PAR03
			cQuery := " SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_EMISSAO, C2_PRODUTO, B1_DESC, B1_CODBAR FROM " + RETSQLNAME("SC2") + " SC2 "
			cQuery += " INNER JOIN " + RetSqlName("SB1") + " SB1 ON SB1.B1_FILIAL = '" + FWxFilial("SB1") + "' AND SB1.B1_COD = SC2.C2_PRODUTO AND SB1.D_E_L_E_T_<>'*'"
			cQuery += " WHERE SC2.C2_FILIAL = '" + FWxFilial("SC2") + "' AND SC2.D_E_L_E_T_<>'*' AND SC2.C2_NUM BETWEEN  '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' ORDER BY SC2.C2_NUM"
			cQuery := ChangeQuery(cQuery)
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"tOP",.T.,.T.)

			If tOP->(eof())
				MsgStop("Nao foram encontrados registros com a(s) OP(s) informada(s)!")
				tOP->(dbCloseArea())
				RETURN
			EndIf

			While tOP->(!Eof())
				aAdd(_aVet,{tOP->C2_NUM,tOP->C2_PRODUTO, tOP->B1_DESC,tOP->B1_CODBAR})
				tOP->(DbSkip())
			End
			tOP->(dbCloseArea())

			If Len(_aVet) > 0
				fConnectZPL()
				impx(_aVet)
			EndIf

		Else 

			nLoop := 0

		EndIf
	
	End

	RestArea(aArea)

Return

/*/{Protheus.doc} xImpEti
Chamada da geração da etiqueta

@type 	function
@author 	Cristiano
@since 	30/06/2022
@Updated Michel Sander 
@Date 	11/07/2022
/*/

Static function impx(_aVet)

	local _cEti  	:= ""
	local nX 	 	:= 0
	local _nQtdEt2	:= _nQtdEti

	For nX := 1 to len(_aVet)

		nCount := 0

		While _nQtdEt2 > 0 

			If nCount == 0
				// Formatação da etiqueta
				_cEti := "CT~~CD,~CC^~CT~"+CRLF
				_cEti += "^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR3,3~SD24^JUS^LRN^CI0^XZ"+CRLF
				_cEti += "^XA"+CRLF
				_cEti += "^MMT"+CRLF
				_cEti += "^PW719"+CRLF
				_cEti += "^LL0320"+CRLF
				_cEti += "^LS0"+CRLF

				// Primeira Etiqueta
				_cEti += "^FT46,320^A0B,45,36^FH\^FDWORLD FILM^FS"+CRLF
				_cEti += "^FT22,120^A0B,27,19^FH\^FDLOTE " + AllTrim(_aVet[nX][1]) + "^FS"+CRLF
				_cEti += "^FT62,95^A0B,29,24^FH\^FD" + AllTrim(_aVet[nX][2]) + "^FS"+CRLF
				_cEti += "^BY2,3,61^FT174,320^BCB,,Y,N"+CRLF
				_cEti += "^FD>;" + SubStr(_aVet[nX][4],1,12) + ">6" + SubStr(_aVet[nX][4],13,1) + "^FS"+CRLF
				_cEti += "^FT105,320^A0B,29,20^FH\^FD" + AllTrim(_aVet[nX][3]) + "^FS"+CRLF
				nCount++
				_nQtdEt2 -= 1

			EndIf 

			// Segunda Etiqueta
			If _nQtdEt2 > 0 
				_cEti += "^FT306,320^A0B,45,36^FH\^FDWORLD FILM^FS"+CRLF
				_cEti += "^FT282,120^A0B,27,19^FH\^FDLOTE " + AllTrim(_aVet[nX][1]) + "^FS"+CRLF
				_cEti += "^FT322,95^A0B,29,24^FH\^FD" + AllTrim(_aVet[nX][2]) + "^FS"+CRLF
				_cEti += "^BY2,3,61^FT434,320^BCB,,Y,N"+CRLF
				_cEti += "^FD>;" + SubStr(_aVet[nX][4],1,12) + ">6" + SubStr(_aVet[nX][4],13,1) + "^FS"+CRLF
				_cEti += "^FT365,320^A0B,29,20^FH\^FD" + AllTrim(_aVet[nX][3]) + "^FS"+CRLF
				nCount++
				_nQtdEt2 -= 1
			EndIf

			// Terceira Etiqueta 
			If _nQtdEt2 > 0
				_cEti += "^FT566,320^A0B,45,36^FH\^FDWORLD FILM^FS"+CRLF
				_cEti += "^FT542,120^A0B,27,19^FH\^FDLOTE " + AllTrim(_aVet[nX][1]) + "^FS"+CRLF
				_cEti += "^FT582,95^A0B,29,24^FH\^FD" + AllTrim(_aVet[nX][2]) + "^FS"+CRLF
				_cEti += "^BY2,3,61^FT694,320^BCB,,Y,N"+CRLF
				_cEti += "^FD>;" + SubStr(_aVet[nX][4],1,12) + ">6" + SubStr(_aVet[nX][4],13,1) + "^FS"+CRLF
				_cEti += "^FT625,320^A0B,29,20^FH\^FD" + AllTrim(_aVet[nX][3]) + "^FS"+CRLF
				nCount++
				_nQtdEt2 -= 1
			EndIf

			// Finalização da etiqueta
			_cEti += "^PQ1,0,1,Y^XZ"+CRLF

			// Impressão da etiqueta
			ImpY(_cEti)
			If _nQtdEt2 > 0
			   nCount := 0
			ENdIf 

		End

	next nY

	If lPrint
		MsgAlert("Etiqueta(s) gerada(s), verifique a impressora!")
	EndIf

Return

/*/{Protheus.doc} fConnectZPL
Captura a porta LPT1 para a impressora ZEBRA

@type 	function
@Updated Michel Sander 
@Date 	11/07/2022
/*/

Static FUnction fConnectZPL()

	LOCAL	fArq 		:= ""
	LOCAL cComando := AllTrim(SuperGetMv("MV_XIMPEXP",,"NET USE LPT1 \\estacao05\ZebraExpedicao /PERSISTENT:YES"))
	LOCAL cPathBat := "C:\SpoolEti"
	LOCAL cBatch   := "C:\SpoolEti\ZEBRA.BAT"

	// Verifica diretório de impressão
	If !ExistDir(cPathBat)
		MakeDir(cPathBat)
	EndIf

	// Criação do arquivo .BAT
	fArq := FCREATE(cBatch,0)
	If fArq == -1
		MsgAlert("Erro ao criar arquivo .BAT de captura da impressora Zebra " + Str(ferror()))
		lPrint := .F.
		Return
	EndIf

	// Gera o arquivo .BAT e executa a captura da impressora
	FWrite(fArq,cComando)
	FClose(fArq)
	ShellExecute('OPEN',cBatch,"","",1)

Return

/*/{Protheus.doc} ImpY
Impressao da etiqueta via porta LPT1

@type 	function
@author 	Cristiano
@since 	30/06/2022
@Updated Michel Sander 
@Date 	11/07/2022
/*/

Static function ImpY(_cEti)

	local nHandle := 0

	If !ExistDir("c:\SpoolEti")
		MakeDir("c:\SpoolEti")
	EndIf

	nHandle := FCREATE("c:\SpoolEti\SpoolEti.prn")

	If nHandle = -1
		MsgAlert("Erro ao criar arquivo Spool de etiqueta - ferror " + Str(ferror()))
		lPrint := .F.
	Else
		FWrite(nHandle,_cEti)
		FClose(nHandle)
		WaitRun("print /d:lpt1 c:\SpoolEti\SpoolEti.prn")
		FERASE("c:\SpoolEti\SpoolEti.prn")
		lPrint := .T.
	Endif

Return
