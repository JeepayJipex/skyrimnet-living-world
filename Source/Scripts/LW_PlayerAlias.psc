Scriptname LW_PlayerAlias extends ReferenceAlias

LW_ContractController Property Controller Auto

Event OnInit()
    If Controller != None
        Controller.Bootstrap(False)
    EndIf
EndEvent

Event OnPlayerLoadGame()
    If Controller != None
        Controller.Bootstrap(True)
    EndIf
EndEvent
