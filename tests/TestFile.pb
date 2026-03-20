EnableExplicit
; TEST FILE V5
; Covers:
; - Global / DeclareModule / Module / MainFile(CompilerIf scope)
; - KEEP
; - DELETE
; - ADD
; - duplicate declares
; - ghost declares
; - wrong type declares
; - DM wins over Module
; - second module with separate scope

; GLOBAL SCOPE
Declare Delete_GlobalGhost()              ; DELETE
Declare Keep_GlobalOk()                   ; KEEP
Declare Keep_GlobalDup()                  ; KEEP
Declare Keep_GlobalDup()                  ; DELETE
Declare.b Keep_GlobalBool()               ; KEEP
Declare.s Keep_GlobalString()             ; KEEP
Declare.s WrongType_Global()              ; DELETE
Declare WrongType_GlobalString()          ; DELETE

Procedure Keep_GlobalOk()
Procedure Keep_GlobalDup()
Procedure.b Keep_GlobalBool()
Procedure.s Keep_GlobalString()
Procedure Add_GlobalMissing()             ; ADD
Procedure.b Add_GlobalBoolMissing()       ; ADD
Procedure.s Add_GlobalStringMissing()     ; ADD
Procedure WrongType_Global()              ; ADD
Procedure.s WrongType_GlobalString()      ; ADD

; DECLAREMODULE TestMod
DeclareModule TestMod
   Declare Delete_DM_Ghost()              ; DELETE
   Declare Keep_DM_Ok()                   ; KEEP
   Declare Keep_DM_Dup()                  ; KEEP
   Declare Keep_DM_Dup()                  ; DELETE
   Declare.b Keep_DM_Bool()               ; KEEP
   Declare.s Keep_DM_String()             ; KEEP
   Declare.s WrongType_DM()               ; DELETE
   Declare WrongType_DMString()           ; DELETE
   Declare Keep_ModuleOk()                ; KEEP
   Declare Keep_ModuleDup()               ; KEEP
   Declare.b Keep_ModuleBool()            ; KEEP
   Declare.s Keep_ModuleString()          ; KEEP

   Procedure Keep_DM_Ok()
   Procedure Keep_DM_Dup()
   Procedure.b Keep_DM_Bool()
   Procedure.s Keep_DM_String()
   Procedure Add_DM_Missing()             ; ADD
   Procedure.b Add_DM_BoolMissing()       ; ADD
   Procedure.s Add_DM_StringMissing()     ; ADD
   Procedure WrongType_DM()               ; ADD
   Procedure.s WrongType_DMString()       ; ADD
EndDeclareModule

; MODULE TestMod
Module TestMod
   Declare Delete_ModuleGhost()           ; DELETE
   Declare Keep_ModuleOk()                ; DELETE
   Declare Keep_ModuleDup()               ; DELETE
   Declare Keep_ModuleDup()               ; DELETE
   Declare.b Keep_ModuleBool()            ; DELETE
   Declare.s Keep_ModuleString()          ; DELETE
   Declare WrongType_ModuleOnly()         ; KEEP
   Declare.s WrongType_ModuleOnlyString() ; KEEP

   Procedure Keep_ModuleOk()
   Procedure Keep_ModuleDup()
   Procedure.b Keep_ModuleBool()
   Procedure.s Keep_ModuleString()
   Procedure Add_ModuleMissing()          ; ADD
   Procedure.b Add_ModuleBoolMissing()    ; ADD
   Procedure.s Add_ModuleStringMissing()  ; ADD
   Procedure WrongType_ModuleOnly()
   Procedure.s WrongType_ModuleOnlyString()
EndModule

; DECLAREMODULE SecondMod
DeclareModule SecondMod
   Declare Delete_Second_DM_Ghost()       ; DELETE
   Declare Keep_Second_DM_Ok()            ; KEEP
   Declare Keep_Second_DM_Dup()           ; KEEP
   Declare Keep_Second_DM_Dup()           ; DELETE
   Declare.b Keep_Second_DM_Bool()        ; KEEP
   Declare.s Keep_Second_DM_String()      ; KEEP
   Declare.s WrongType_Second_DM()        ; DELETE
   Declare WrongType_Second_DMString()    ; DELETE
   Declare Keep_Second_ModuleOk()         ; KEEP
   Declare Keep_Second_ModuleDup()        ; KEEP
   Declare.b Keep_Second_ModuleBool()     ; KEEP
   Declare.s Keep_Second_ModuleString()   ; KEEP

   Procedure Keep_Second_DM_Ok()
   Procedure Keep_Second_DM_Dup()
   Procedure.b Keep_Second_DM_Bool()
   Procedure.s Keep_Second_DM_String()
   Procedure Add_Second_DM_Missing()          ; ADD
   Procedure.b Add_Second_DM_BoolMissing()    ; ADD
   Procedure.s Add_Second_DM_StringMissing()  ; ADD
   Procedure WrongType_Second_DM()            ; ADD
   Procedure.s WrongType_Second_DMString()    ; ADD
EndDeclareModule

; MODULE SecondMod
Module SecondMod
   Declare Delete_Second_ModuleGhost()           ; DELETE
   Declare Keep_Second_ModuleOk()                ; DELETE
   Declare Keep_Second_ModuleDup()               ; DELETE
   Declare Keep_Second_ModuleDup()               ; DELETE
   Declare.b Keep_Second_ModuleBool()            ; DELETE
   Declare.s Keep_Second_ModuleString()          ; DELETE
   Declare WrongType_Second_ModuleOnly()         ; KEEP
   Declare.s WrongType_Second_ModuleOnlyString() ; KEEP

   Procedure Keep_Second_ModuleOk()
   Procedure Keep_Second_ModuleDup()
   Procedure.b Keep_Second_ModuleBool()
   Procedure.s Keep_Second_ModuleString()
   Procedure Add_Second_ModuleMissing()          ; ADD
   Procedure.b Add_Second_ModuleBoolMissing()    ; ADD
   Procedure.s Add_Second_ModuleStringMissing()  ; ADD
   Procedure WrongType_Second_ModuleOnly()
   Procedure.s WrongType_Second_ModuleOnlyString()
EndModule

; MAIN FILE / COMPILERIF SCOPE
CompilerIf #PB_Compiler_IsMainFile
   Declare Delete_MainGhost()              ; DELETE
   Declare Keep_MainOk()                   ; KEEP
   Declare Keep_MainDup()                  ; KEEP
   Declare Keep_MainDup()                  ; DELETE
   Declare.b Keep_MainBool()               ; KEEP
   Declare.s Keep_MainString()             ; KEEP
   Declare.s WrongType_Main()              ; DELETE
   Declare WrongType_MainString()          ; DELETE

   Procedure Keep_MainOk()
   Procedure Keep_MainDup()
   Procedure.b Keep_MainBool()
   Procedure.s Keep_MainString()
   Procedure Add_MainMissing()             ; ADD
   Procedure.b Add_MainBoolMissing()       ; ADD
   Procedure.s Add_MainStringMissing()     ; ADD
   Procedure WrongType_Main()              ; ADD
   Procedure.s WrongType_MainString()      ; ADD
CompilerEndIf
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 149
; FirstLine = 68
; Folding = ----------
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DisableDebugger