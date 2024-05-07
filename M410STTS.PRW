#INCLUDE "Protheus.CH"

/*/{Protheus.doc} M410STTS
Ponto de Entrada após a gravação do pedido de vendas 

@type 	function
@author Michel Sander
@since 	25/07/2022
@Date 	11/07/2022
@version 1.0
/*/

User Function M410STTS()

    Local aArea    := GetArea()
    Local aAreaC5  := SC5->(GetArea())
    Local aAreaC6  := SC6->(GetArea())
    Local aAreaC9  := SC9->(GetArea())
    Local aAreaAux := { aAreaC5, aAreaC6, aAreaC9, aArea }
 
    RecLock('SC5', .F.)
    SC5->C5_XSEPARA := "N"
    SC5->(MsUnlock())
 
    AEval(aAreaAux, {|x| RestArea(x)})

Return
