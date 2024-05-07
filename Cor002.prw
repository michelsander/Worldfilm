#INCLUDE "PROTHEUS.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} MTA440C9 
Ponto de entrada no momento da liberaï¿½ï¿½o de um pedido de vendas(MATA410) 

@author Michel Sander
@since 11/06/2018
@version 1.0
/*/
//-------------------------------------------------------------------

User Function MTA440C9()

	Local lRet := .T.
	Local aAreaSC9 := SC9->(GetArea())
	Local aAreaSC5 := SC5->(GetArea())
	Local aAreaSC6 := SC6->(GetArea())
	Local aAreas   := { aAreaSC5, aAreaSC6, aAreaSC9, GetArea() }

	If !FwIsInCallStack('MA521MARKB')
		
		If !Reclock("SC5",.F.)
			Help( ,, "MTA440C9",, "Pedido "+SC5->C5_NUM+" está em uso por outro usuário. Aguarde um instante e tente novamente.", 1, 0 )
			lRet := .F.
		Endif 

		If lRet 
		   SC5->C5_XSEPARA := "N"
			SC5->(MsUnlock())
		EndIf 

		If SC9->( dbSeek( xFilial("SC9") + SC5->C5_NUM ) ) .And. lRet
		
			While !SC9->( Eof() ) .And. xFilial("SC9") + SC5->C5_NUM == SC9->C9_FILIAL + SC9->C9_PEDIDO
				RecLock("SC9",.F.)
				SC9->C9_BLWMS := "03"
				SC9->(MsUnlock())
				SC9->( dbSkip() )
			End

		EndIf

	EndIf

	AEval(aAreas, { |x| RestArea(x)} )

Return lRet
