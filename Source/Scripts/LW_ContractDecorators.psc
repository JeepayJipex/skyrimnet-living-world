Scriptname LW_ContractDecorators Hidden

; SkyrimNet calls global functions; the controller is looked up by quest EditorID.
String Function CanOffer(Actor akActor) Global
    LW_ContractController controller = Quest.GetQuest("LW_ContractController") as LW_ContractController
    If controller == None
        Return "unavailable"
    EndIf
    If controller.CanOffer(akActor)
        Return "eligible"
    EndIf
    Return "unavailable"
EndFunction

String Function ContractContext(Actor akActor) Global
    LW_ContractController controller = Quest.GetQuest("LW_ContractController") as LW_ContractController
    If controller == None
        Return ""
    EndIf
    Return controller.GetContractContext(akActor)
EndFunction
