#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} MT103IPC
Ponto de entrada para preenchimento do LOTE e SERIAL automático na entrada de NF 

@author  MIchel Sander
@type    function
@since   04/08/2021
@version 1.0
@return  Nil
/*/

User Function MT103IPC()

   Local ExpN1      := PARAMIXB[1]
   LOCAL nPosLote   := aScan(aHeader,{|x| AllTrim(x[2])=="D1_LOTECTL"})
   LOCAL nPosSerial := aScan(aHeader,{|x| AllTrim(x[2])=="D1_XSERIE"})

   If nPosLote > 0
      aCols[ExpN1,nPosLote] := SC7->C7_XLOTE
   EndIf 

   If nPosSerial > 0
      aCols[ExpN1,nPosSerial] := SC7->C7_XSERIE
   EndIf 

Return NIL

