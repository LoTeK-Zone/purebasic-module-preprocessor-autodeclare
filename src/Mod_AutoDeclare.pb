; ==================================================================================================
; File: Mod_PreProcessor_AutoDeclare.pb
; Description: Automatic declaration of procedures and removal of wrong declares in source code files with or without modules.
; Author: Stephan Kühn (LoTeK)
; Mail: info@lotek-zone.com
; Web: https://lotek-zone.com/
; GitHub: https://github.com/LoTeK-Zone
; Repository: https://github.com/LoTeK-Zone/PureBasic_PreProcessor_AutoDeclare
; Version: v0.3.0
; Last-Updated: 2026-03-20
; License: MIT
; ==================================================================================================

;- App-Info
#APP_NAME$        = "PureBasic_Mod_PreProcessor_AutoDeclare"
#APP_DESCRIPTION  = "Automatic declaration of procedures and removal of wrong declares in source code files with or without modules."
#APP_VERSION$     = "v0.3.0"
#APP_AUTHOR$      = "LoTeK (Stephan Kühn)"
#APP_WEBSITE$     = "https://lotek-zone.com"
#APP_EMAIL$       = "info@lotek-zone.com"
#APP_LAST_UPDATED = "2026-03-20"
#APP_LICENSE$     = "MIT"

EnableExplicit

DeclareModule Mod_PreProcessor_AutoDeclare

   EnableExplicit

   ;- Public Constants / Settings
   #DEBUG_MODE                       = #False ; Debugs Information with PureBasic Command: Debug() only if SourceCode is not compiled to an .exe program. Bebug-Mode does not writes changes to SourceCode File.
   #TEST_FILE_MODE                   = #False ; TestFileMode - uses a TestFile Instead of Checking a ProgramParameter (useful for fast checks if program is not a compiled .exe)
   #TEST_FILE$                       = "../tests/TestFile.pb" ; Name of TestFile
   #WRITE_LOG                        = #False ; Writes LogFile
   #LOG_FILE$                        = "Log.txt" ; Name of LogFile
   #BLANK_LINES_BEFORE_DECLARE_BLOCK = 1 ; Blank Lines written before Declare Block
   #BLANK_LINES_AFTER_DECLARE_BLOCK  = 1 ; Blank Lines written after Declare Block
   #INDENTATION                      = " " ; Or: #TAB$

   ;- Public Declare
   Declare Init()

EndDeclareModule

Module Mod_PreProcessor_AutoDeclare

   ;- Private Enumeration
   Enumeration
      #SCOPE_GLOBAL
      #SCOPE_DECLAREMODULE
      #SCOPE_MODULE
      #SCOPE_COMPILER_IF
   EndEnumeration

   Enumeration
      #JOB_DELETE_DECLARE
      #JOB_GENERATE_DECLARE
   EndEnumeration

   ;- Private Structure
   Structure JobEntry
      JobType.a
      InsertLine.q
      DeleteLine.q
      sName$
      sModuleName$
      UseIndent.b
      Scope.q
   EndStructure

   Structure ScopeEntry
      ScopeType.q
      sModuleName$
      StartLine.q
      EndLine.q
      EnableExplicitFound.b
      EnableExplicitLine.q
      InsertLine.q
   EndStructure

   Structure ProcedureEntry
      sName$
      sNameAndModule$
      LineNr.q
      Scope.q
      sModuleName$
   EndStructure

   Structure DeclareEntry
      sName$
      sNameAndModule$
      LineNr.q
      Scope.q
      sModuleName$
      bToDelete.b
   EndStructure

   Structure strDeclareData
      bSourceChanged.b
      List listScopes.ScopeEntry()
      List listProcedures.ProcedureEntry()
      List listDeclares.DeclareEntry()
   EndStructure

   Structure ModuleIndent
      moduleType.a
      bIndent.b
   EndStructure

   Structure strOptions
      bDebugMode.b
      bTestFileMode.b
      sTestFile$
      bWriteLog.b
      sLogFile$
      sIndent$
      aBlankLinesBeforeDeclareBlock.a
      aBlankLinesAfterDeclareBlock.a
      qIDSourceFile.q
      qIdLogFile.q
      qSourceEncoding.q
      bSourceHasBOM.b
      List listIntend.ModuleIndent()
   EndStructure

   ;- Private Define
   Define declareData.strDeclareData
   Define NewList listJobs.JobEntry()
   Define options.strOptions

   ;- Private Declare
   Declare AddJob_DeleteDeclare(line.q, name$, scope.q, sModuleName$)
   Declare AddJob_DeleteDeclare_Safe(line.q, name$, scope.q, sModuleName$)
   Declare AddJob_GenerateDeclare(name$, scope.q, sModuleName$)
   Declare BuildJobList()
   Declare BuildJobs_DeleteDuplicateDeclares()
   Declare BuildJobs_DeleteOrphanDeclares()
   Declare BuildJobs_GenerateMissingDeclares()
   Declare BuildJobs_SpecialModulePass_DM_WinsAlways()
   Declare ClearListsDeclareData()
   Declare CollectTempLists(List listTempProc$(), List listTempDecl$())
   Declare DebugJobList()
   Declare DeletePendingGenerateForModule(sModuleName$, signature$)
   Declare ProcessProceduresAndDeclares(sLine$, qLineNr.q)
   Declare ProcessSource(List listSourceLines$())
   Declare ScanScopes(sLine$, qLineNr.q)
   Declare SetOptions()
   Declare StartNewScope(scope.q, startLine.q, insertLine.q, sModuleName$ = "")
   Declare.b ApplyJobsToSourceByRef(List listSourceLines$())
   Declare.b checkFile(strSourceFile$)
   Declare.b DeclareExists(name$, sModuleName$, scope.q)
   Declare.b DeleteJobExists(line.q)
   Declare.b GetIndentByScope(scope.q)
   Declare.b IsDeclareModulePresent(sModuleName$)
   Declare.b ListHasLine(List listByRef$(), sNeedle$)
   Declare.b LoadSource(strSourceFile$, List listSourceLines$())
   Declare.b ProcedureExists(name$, sModuleName$, scope.q)
   Declare.b WriteSourceFile(strSourceFile$, List listSourceLines$())
   Declare.q FindScopeInsertLine(scope.q, sModuleName$ = "")
   Declare.q GetDuplicateLinesFromListByRef(List listInputByRef$(), List listResultByRef$())
   Declare.q GetFirstGlobalInsertLine()
   Declare.s BuildDeclareLineFromJob(sName$, bUseIndent.b)
   Declare.s BuildNameModuleScopeKey(sName$, sModuleName$, scope.q)
   Declare.s checkParameter()
   Declare.s CollapseWhitespace(sText$)
   Declare.s ParseSignature(sLine$, keyword$)
   Declare.s RemoveBOM(sLine$)

   ;- Private Procedures
   ; -----------------------------------------------------------------------------------------------
   ; Init()
   ;
   ; Entry point for the PreProcessor module.
   ;
   ; Workflow:
   ; 1. Read source file
   ; 2. Scan scopes, declarations and procedure-names
   ; 3. Build job list
   ; 4. Apply modifications to source
   ; -----------------------------------------------------------------------------------------------

   Procedure Init()
      Shared declareData
      Shared options
      Protected NewList listSourceLines$()
      Protected strSourceFile$

      SetOptions()

      If options\bWriteLog = #True And options\sLogFile$ <> "" ; Opening Log-File
         options\qIdLogFile = CreateFile(#PB_Any, options\sLogFile$)
         If Not options\qIdLogFile
            MessageRequester("Error", "Log file could not be created: " + options\sLogFile$)
            End
         EndIf
         WriteStringN(options\qIdLogFile, "=== Log Start ===")
      EndIf


      If options\bTestFileMode = #True
         strSourceFile$ = options\sTestFile$
      Else
         strSourceFile$ = checkParameter()
      EndIf

      If strSourceFile$ = ""
         End
      EndIf

      If checkFile(strSourceFile$) = #False
         End
      EndIf

      If LoadSource(strSourceFile$, listSourceLines$()) = #False
         End
      EndIf

      declareData\bSourceChanged = #False
      ClearListsDeclareData()
      ProcessSource(listSourceLines$())
      BuildJobList()

      If options\bDebugMode = #True Or options\bWriteLog = #True
         DebugJobList()
      EndIf

      ApplyJobsToSourceByRef(listSourceLines$())

      If options\bDebugMode = #True
         ForEach listSourceLines$()
            Debug listSourceLines$()
         Next
      EndIf

      If declareData\bSourceChanged = #True And options\bDebugMode = #False
         ForEach listSourceLines$()
            Debug listSourceLines$()
         Next
         WriteSourceFile(strSourceFile$, listSourceLines$())
      EndIf

      If options\bWriteLog = #True ; Closing Log-File
         WriteStringN(options\qIdLogFile, "=== NEW SOURCE LINES START ===")
         ForEach listSourceLines$()
            WriteStringN(options\qIdLogFile, listSourceLines$())
         Next
         WriteStringN(options\qIdLogFile, "=== NEW SOURCE LINES END ===")
         WriteStringN(options\qIdLogFile, "=== Log End ===")
         CloseFile(options\qIdLogFile)
      EndIf

      End
   EndProcedure

   Procedure.s checkParameter() ; checks the ide programm parameter(0) = filename (including path) of the source file
      Protected strSourceFile$

      strSourceFile$ = ProgramParameter(0)
      If strSourceFile$ = ""
         MessageRequester("PreCompiler Error", "Please send the valid sourcecode filename as only parameter.", #PB_MessageRequester_Error)
         End
      EndIf
      ProcedureReturn strSourceFile$

   EndProcedure

   Procedure.b checkFile(strSourceFile$) ; checks if file exists
      Protected FileSize

      If FileSize(strSourceFile$) > -1
         ProcedureReturn #True
      Else
         MessageRequester("PreCompiler Error", "File does not exists." + Chr(13) + Chr(10) + "<" + strSourceFile$ + ">", #PB_MessageRequester_Error)
         ProcedureReturn #False
      EndIf
   EndProcedure

   Procedure.s CollapseWhitespace(sText$)
      Protected sText2$, token$
      Protected i, n

      ; normalize tabs to spaces
      sText$ = Trim(sText$ )
      sText$ = ReplaceString(sText$, Chr(9), " ")

      ; build tokens, skipping empty fields caused by multiple spaces
      n = CountString(sText$, " ") + 1
      For i = 1 To n
         token$ = StringField(sText$, i, " ")
         If token$ <> ""
            If sText2$ <> ""
               sText2$ + " "
            EndIf
            sText2$ + token$
         EndIf
      Next

      ProcedureReturn sText2$
   EndProcedure

   Procedure.s RemoveBOM(sLine$)
      ; Unicode BOM (U+FEFF)
      If Len(sLine$) > 0
         If Asc(sLine$) = $FEFF
            ProcedureReturn Mid(sLine$, 2)
         EndIf
      EndIf
      ProcedureReturn sLine$
   EndProcedure

   Procedure StartNewScope(scope.q, startLine.q, insertLine.q, sModuleName$ = "")
      Shared declareData

      AddElement(declareData\listScopes())
      declareData\listScopes()\ScopeType    = scope
      declareData\listScopes()\sModuleName$ = sModuleName$
      declareData\listScopes()\StartLine    = startLine
      declareData\listScopes()\InsertLine   = insertLine
   EndProcedure

   Procedure ScanScopes(sLine$, qLineNr.q)
      Shared declareData
      Protected sName$
      Static scope.q
      Static scanScopeStart.b = #True

      If qLineNr = 1
         sLine$ = RemoveBOM(sLine$)
      EndIf
      
      If scanScopeStart = #True
         scope  = #SCOPE_GLOBAL
      EndIf   

      If FindString(sLine$, "DeclareModule ", 1, #PB_String_NoCase) = 1
         sName$ = Trim(StringField(sLine$, 2, " "))
         StartNewScope(#SCOPE_DECLAREMODULE, qLineNr, qLineNr + 1, sName$)
         scope = #SCOPE_DECLAREMODULE
         ProcedureReturn
      EndIf

      If FindString(sLine$, "EndDeclareModule", 1, #PB_String_NoCase) = 1
         StartNewScope(#SCOPE_GLOBAL, qLineNr + 1, qLineNr + 1, "")
         scope = #SCOPE_GLOBAL
         ProcedureReturn
      EndIf

      If FindString(sLine$, "Module ", 1, #PB_String_NoCase) = 1
         sName$ = Trim(StringField(sLine$, 2, " "))
         StartNewScope(#SCOPE_MODULE, qLineNr, qLineNr + 1, sName$)
         scope = #SCOPE_MODULE
         ProcedureReturn
      EndIf

      If FindString(sLine$, "EndModule", 1, #PB_String_NoCase) = 1
         StartNewScope(#SCOPE_GLOBAL, qLineNr + 1, qLineNr + 1, "")
         scope = #SCOPE_GLOBAL
         ProcedureReturn
      EndIf

      If FindString(sLine$, "CompilerIf #PB_Compiler_IsMainFile", 1, #PB_String_NoCase) = 1
         StartNewScope(#SCOPE_COMPILER_IF, qLineNr + 1, qLineNr + 1, "")
         scope = #SCOPE_COMPILER_IF
         ProcedureReturn
      EndIf

      If FindString(sLine$, "CompilerEndIf", 1, #PB_String_NoCase) = 1
         If scope = #SCOPE_COMPILER_IF
            StartNewScope(#SCOPE_GLOBAL, qLineNr + 1, qLineNr + 1, "")
            scope = #SCOPE_GLOBAL
         ElseIf scope = #SCOPE_GLOBAL
            declareData\listScopes()\StartLine = qLineNr + 1
         EndIf
      EndIf

      If scanScopeStart = #True And scope = #SCOPE_GLOBAL
         StartNewScope(#SCOPE_GLOBAL, 1, 1, "")
      EndIf

      If FindString(sLine$, "EnableExplicit", 1, #PB_String_NoCase) = 1
         declareData\listScopes()\EnableExplicitFound = #True
         declareData\listScopes()\EnableExplicitLine  = qLineNr
         declareData\listScopes()\InsertLine          = qLineNr + 1
         ProcedureReturn
      EndIf
     
      scanScopeStart = #False
      
   EndProcedure

   Procedure ClearListsDeclareData()
      Shared declareData

      ClearList(declareData\listScopes())
      ClearList(declareData\listProcedures())
      ClearList(declareData\listDeclares())
   EndProcedure

   Procedure ProcessSource(List listSourceLines$())
      Shared declareData
      Protected qLineNr.q = 0
      Protected sLine$

      ForEach listSourceLines$()
         qLineNr + 1
         sLine$ = listSourceLines$()
         sLine$ = Trim(StringField(sLine$, 1, ";"))
         If sLine$ = ""
            Continue
         EndIf

         ScanScopes(sLine$, qLineNr)
         ProcessProceduresAndDeclares(sLine$, qLineNr)
      Next
   EndProcedure

   Procedure.s ParseSignature(sLine$, keyword$)
      Protected s$
      Protected tail$
      Protected sig$
      Protected pos.i
      Protected keywordWithSpace$ = keyword$ + " "
      Protected keywordWithDot$ = keyword$ + "."
      Protected keywordDLL$ = keyword$ + "DLL"

      s$ = Trim(sLine$)

      pos = FindString(s$, ";", 1)
      If pos > 0
         s$ = Trim(Left(s$, pos - 1))
      EndIf

      If s$ = ""
         ProcedureReturn ""
      EndIf

      If FindString(s$, keywordDLL$, 1, #PB_String_NoCase) = 1
         ProcedureReturn ""
      EndIf

      If FindString(s$, keywordWithDot$, 1, #PB_String_NoCase) = 1
         tail$ = Trim(Mid(s$, Len(keyword$) + 1))
         If Left(tail$, 1) = "."
            sig$ = CollapseWhitespace(tail$)
         Else
            sig$ = "." + CollapseWhitespace(tail$)
         EndIf
         ProcedureReturn sig$
      EndIf

      If FindString(s$, keywordWithSpace$, 1, #PB_String_NoCase) = 1
         tail$ = Trim(Mid(s$, Len(keywordWithSpace$) + 1))
         sig$  = CollapseWhitespace(tail$)
         ProcedureReturn sig$
      EndIf

      ProcedureReturn ""
   EndProcedure

   Procedure ProcessProceduresAndDeclares(sLine$, qLineNr.q)
      Shared declareData

      Protected sName$
      Protected sModuleName$
      Protected sNameAndModule$
      Protected scope.q

      If ListSize(declareData\listScopes()) = 0
         ProcedureReturn
      EndIf

      scope        = declareData\listScopes()\ScopeType
      sModuleName$ = declareData\listScopes()\sModuleName$

      sName$ = ParseSignature(sLine$, "Procedure")
      If sName$
         sNameAndModule$ = LCase(sName$ + "|" + sModuleName$)
         AddElement(declareData\listProcedures())
         declareData\listProcedures()\LineNr          = qLineNr
         declareData\listProcedures()\Scope           = scope
         declareData\listProcedures()\sModuleName$    = sModuleName$
         declareData\listProcedures()\sName$          = sName$
         declareData\listProcedures()\sNameAndModule$ = sNameAndModule$
         ProcedureReturn
      EndIf

      sName$ = ParseSignature(sLine$, "Declare")
      If sName$
         sNameAndModule$ = LCase(sName$ + "|" + sModuleName$)
         AddElement(declareData\listDeclares())
         declareData\listDeclares()\LineNr          = qLineNr
         declareData\listDeclares()\Scope           = scope
         declareData\listDeclares()\sModuleName$    = sModuleName$
         declareData\listDeclares()\sName$          = sName$
         declareData\listDeclares()\sNameAndModule$ = sNameAndModule$
      EndIf
   EndProcedure

   Procedure SetOptions()
      Shared options

      ClearList(options\listIntend())

      options\bDebugMode      = #DEBUG_MODE
      options\bTestFileMode   = #TEST_FILE_MODE
      options\sTestFile$      = #TEST_FILE$
      options\bWriteLog       = #WRITE_LOG
      options\sLogFile$       = #LOG_FILE$
      options\qSourceEncoding = #PB_UTF8
      options\bSourceHasBOM   = #False
      options\sIndent$        = #INDENTATION

      options\aBlankLinesBeforeDeclareBlock = #BLANK_LINES_BEFORE_DECLARE_BLOCK
      options\aBlankLinesAfterDeclareBlock  = #BLANK_LINES_AFTER_DECLARE_BLOCK

      AddElement(options\listIntend())
      options\listIntend()\moduleType = #SCOPE_GLOBAL
      options\listIntend()\bIndent    = #False
      AddElement(options\listIntend())
      options\listIntend()\moduleType = #SCOPE_DECLAREMODULE
      options\listIntend()\bIndent    = #True
      AddElement(options\listIntend())
      options\listIntend()\moduleType = #SCOPE_MODULE
      options\listIntend()\bIndent    = #True
      AddElement(options\listIntend())
      options\listIntend()\moduleType = #SCOPE_COMPILER_IF
      options\listIntend()\bIndent    = #True
   EndProcedure

   Procedure.b LoadSource(strSourceFile$, List listSourceLines$()) ; Loads the Source File and writes lines to list
      Shared options
      Protected qReadFormat.q

      options\qIdSourceFile = ReadFile(#PB_Any, strSourceFile$)

      If options\qIdSourceFile
         ClearList(listSourceLines$())

         qReadFormat           = ReadStringFormat(options\qIdSourceFile)
         options\bSourceHasBOM = #False

         Select qReadFormat
            Case #PB_Ascii
               options\qSourceEncoding = #PB_Ascii

            Case #PB_UTF8
               options\qSourceEncoding = #PB_UTF8
               options\bSourceHasBOM   = #True

            Case #PB_Unicode
               options\qSourceEncoding = #PB_Unicode
               options\bSourceHasBOM   = #True

            Default
               CloseFile(options\qIdSourceFile)
               options\qIdSourceFile = 0
               MessageRequester("PreCompiler Error", "Unsupported source encoding: " + strSourceFile$, #PB_MessageRequester_Error)
               ProcedureReturn #False
         EndSelect

         While Not Eof(options\qIdSourceFile)
            AddElement(listSourceLines$())
            listSourceLines$() = ReadString(options\qIdSourceFile, options\qSourceEncoding)
         Wend

         CloseFile(options\qIdSourceFile)
         options\qIdSourceFile = 0

         ProcedureReturn #True
      Else
         ProcedureReturn #False
      EndIf
   EndProcedure

   Procedure DebugJobList()
      Shared options
      Shared listJobs()

      Protected sMsg$

      sMsg$ = "=== Job List Start ==="

      ForEach listJobs()
         sMsg$ + #CRLF$ +
         "JobType=" + Str(listJobs()\JobType) +
         " | Scope=" + Str(listJobs()\Scope) +
         " | Insert=" + Str(listJobs()\InsertLine) +
         " | Delete=" + Str(listJobs()\DeleteLine) +
         " | Name=" + listJobs()\sName$
      Next

      sMsg$ + #CRLF$ + "=== Job List End ==="

      If options\bTestFileMode = #True And options\bDebugMode = #True
         Debug sMsg$
      EndIf

      If options\bWriteLog = #True
         WriteStringN(options\qIdLogFile, sMsg$)
      EndIf
   EndProcedure

   Procedure.s BuildNameModuleScopeKey(sName$, sModuleName$, scope.q)
      ProcedureReturn sName$ + "|" + sModuleName$ + "|" + Str(scope)
   EndProcedure

   Procedure.q FindScopeInsertLine(scope.q, sModuleName$ = "")
      Shared declareData
      Protected qStart.q
      Protected qEnable.q

      If scope = #SCOPE_GLOBAL
         ProcedureReturn GetFirstGlobalInsertLine()
      EndIf

      ForEach declareData\listScopes()
         If declareData\listScopes()\ScopeType = scope
            If declareData\listScopes()\sModuleName$ = sModuleName$
               qStart  = declareData\listScopes()\StartLine
               qEnable = declareData\listScopes()\EnableExplicitLine

               If qEnable > 0
                  ProcedureReturn qEnable + 1
               Else
                  ProcedureReturn qStart + 1
               EndIf
            EndIf
         EndIf
      Next

      ProcedureReturn 1
   EndProcedure

   Procedure.b IsDeclareModulePresent(sModuleName$)
      Shared declareData

      ForEach declareData\listScopes()
         If declareData\listScopes()\ScopeType = #SCOPE_DECLAREMODULE And declareData\listScopes()\sModuleName$ = sModuleName$
            ProcedureReturn #True
         EndIf
      Next

      ProcedureReturn #False
   EndProcedure

   Procedure.b GetIndentByScope(scope.q)
      Shared options

      ForEach options\listIntend()
         If options\listIntend()\moduleType = scope
            ProcedureReturn options\listIntend()\bIndent
         EndIf
      Next

      ProcedureReturn #False
   EndProcedure

   Procedure.b DeleteJobExists(line.q)
      Shared listJobs()

      ForEach listJobs()
         If listJobs()\JobType = #JOB_DELETE_DECLARE And listJobs()\DeleteLine = line
            ProcedureReturn #True
         EndIf
      Next

      ProcedureReturn #False
   EndProcedure

   Procedure AddJob_DeleteDeclare_Safe(line.q, name$, scope.q, sModuleName$)
      If DeleteJobExists(line)
         ProcedureReturn
      EndIf

      AddJob_DeleteDeclare(line, name$, scope, sModuleName$)
   EndProcedure

   Procedure AddJob_DeleteDeclare(line.q, name$, scope.q, sModuleName$)
      Shared listJobs()

      AddElement(listJobs())
      listJobs()\JobType      = #JOB_DELETE_DECLARE
      listJobs()\DeleteLine   = line
      listJobs()\sName$       = name$
      listJobs()\sModuleName$ = sModuleName$
      listJobs()\Scope        = scope
   EndProcedure

   Procedure AddJob_GenerateDeclare(name$, scope.q, sModuleName$)
      Shared listJobs()
      Protected qInsertLine.q

      qInsertLine = FindScopeInsertLine(scope, sModuleName$)
      If qInsertLine <= 0
         qInsertLine = 1
      EndIf

      AddElement(listJobs())
      listJobs()\JobType      = #JOB_GENERATE_DECLARE
      listJobs()\Scope        = scope
      listJobs()\sName$       = name$
      listJobs()\sModuleName$ = sModuleName$
      listJobs()\UseIndent    = GetIndentByScope(scope)
      listJobs()\InsertLine   = qInsertLine
   EndProcedure

   Procedure CollectTempLists(List listTempProc$(), List listTempDecl$())
      Shared declareData

      ClearList(listTempProc$())
      ClearList(listTempDecl$())

      ForEach declareData\listProcedures()
         AddElement(listTempProc$())
         listTempProc$() = BuildNameModuleScopeKey(declareData\listProcedures()\sName$, declareData\listProcedures()\sModuleName$, declareData\listProcedures()\Scope)
      Next

      ForEach declareData\listDeclares()
         AddElement(listTempDecl$())
         listTempDecl$() = BuildNameModuleScopeKey(declareData\listDeclares()\sName$, declareData\listDeclares()\sModuleName$, declareData\listDeclares()\Scope)
      Next
   EndProcedure

   Procedure DeletePendingGenerateForModule(sModuleName$, signature$)
      Shared listJobs()

      ForEach listJobs()
         If listJobs()\JobType = #JOB_GENERATE_DECLARE
            If listJobs()\Scope = #SCOPE_MODULE And listJobs()\sModuleName$ = sModuleName$
               If listJobs()\sName$ = signature$
                  DeleteElement(listJobs())
                  Break
               EndIf
            EndIf
         EndIf
      Next
   EndProcedure

   Procedure BuildJobs_DeleteDuplicateDeclares()
      Shared declareData
      Protected firstFound.b
      Protected sKey$
      Protected NewList listTempDecl$()
      Protected NewList listDupKeys$()

      ClearList(listTempDecl$())
      ClearList(listDupKeys$())

      ForEach declareData\listDeclares()
         AddElement(listTempDecl$())
         listTempDecl$() = BuildNameModuleScopeKey(declareData\listDeclares()\sName$, declareData\listDeclares()\sModuleName$, declareData\listDeclares()\Scope)
      Next

      If GetDuplicateLinesFromListByRef(listTempDecl$(), listDupKeys$()) > 0
         ForEach listDupKeys$()
            firstFound = #True

            ForEach declareData\listDeclares()
               sKey$ = BuildNameModuleScopeKey(declareData\listDeclares()\sName$, declareData\listDeclares()\sModuleName$, declareData\listDeclares()\Scope)

               If sKey$ = listDupKeys$()
                  If firstFound = #True
                     firstFound = #False
                  Else
                     AddJob_DeleteDeclare_Safe(declareData\listDeclares()\LineNr, declareData\listDeclares()\sName$, declareData\listDeclares()\Scope, declareData\listDeclares()\sModuleName$)
                  EndIf
               EndIf
            Next
         Next
      EndIf
   EndProcedure

   Procedure.b ListHasLine(List listByRef$(), sNeedle$)
      ForEach listByRef$()
         If listByRef$() = sNeedle$
            ProcedureReturn #True
         EndIf
      Next

      ProcedureReturn #False
   EndProcedure

   Procedure BuildJobs_GenerateMissingDeclares()
      Shared declareData
      Protected sName$
      Protected sModuleName$
      Protected scope.q
      Protected sKeyTarget$
      Protected sKeyDM$
      Protected sKeyModule$
      Protected sKeyGlobal$
      Protected sKeyCompilerIf$

      Protected NewList listDeclKeys$()

      ClearList(listDeclKeys$())

      ForEach declareData\listDeclares()
         AddElement(listDeclKeys$())
         listDeclKeys$() = BuildNameModuleScopeKey(declareData\listDeclares()\sName$, declareData\listDeclares()\sModuleName$, declareData\listDeclares()\Scope)
      Next

      ForEach declareData\listProcedures()
         sName$       = declareData\listProcedures()\sName$
         sModuleName$ = declareData\listProcedures()\sModuleName$
         scope        = declareData\listProcedures()\Scope

         Select scope
            Case #SCOPE_GLOBAL
               sKeyGlobal$ = BuildNameModuleScopeKey(sName$, "", #SCOPE_GLOBAL)

               If ListHasLine(listDeclKeys$(), sKeyGlobal$) = #False
                  AddJob_GenerateDeclare(sName$, #SCOPE_GLOBAL, "")
               EndIf

            Case #SCOPE_DECLAREMODULE
               sKeyDM$ = BuildNameModuleScopeKey(sName$, sModuleName$, #SCOPE_DECLAREMODULE)

               If ListHasLine(listDeclKeys$(), sKeyDM$) = #False
                  AddJob_GenerateDeclare(sName$, #SCOPE_DECLAREMODULE, sModuleName$)
               EndIf

            Case #SCOPE_MODULE
               sKeyDM$     = BuildNameModuleScopeKey(sName$, sModuleName$, #SCOPE_DECLAREMODULE)
               sKeyModule$ = BuildNameModuleScopeKey(sName$, sModuleName$, #SCOPE_MODULE)

               If ListHasLine(listDeclKeys$(), sKeyDM$) = #False
                  If ListHasLine(listDeclKeys$(), sKeyModule$) = #False
                     AddJob_GenerateDeclare(sName$, #SCOPE_MODULE, sModuleName$)
                  EndIf
               EndIf

            Case #SCOPE_COMPILER_IF
               sKeyCompilerIf$ = BuildNameModuleScopeKey(sName$, "", #SCOPE_COMPILER_IF)

               If ListHasLine(listDeclKeys$(), sKeyCompilerIf$) = #False
                  AddJob_GenerateDeclare(sName$, #SCOPE_COMPILER_IF, "")
               EndIf

         EndSelect
      Next
   EndProcedure

   Procedure BuildJobs_DeleteOrphanDeclares()
      Shared declareData
      Protected sName$
      Protected sModuleName$
      Protected scope.q
      Protected bKeep.b
      Protected sKeyGlobal$
      Protected sKeyDM$
      Protected sKeyModule$
      Protected sKeyCompilerIf$
      Protected NewList listProcKeys$()
      Protected NewList listDeclKeys$()

      ClearList(listProcKeys$())
      ClearList(listDeclKeys$())

      ForEach declareData\listProcedures()
         AddElement(listProcKeys$())
         listProcKeys$() = BuildNameModuleScopeKey(declareData\listProcedures()\sName$, declareData\listProcedures()\sModuleName$, declareData\listProcedures()\Scope)
      Next

      ForEach declareData\listDeclares()
         AddElement(listDeclKeys$())
         listDeclKeys$() = BuildNameModuleScopeKey(declareData\listDeclares()\sName$, declareData\listDeclares()\sModuleName$, declareData\listDeclares()\Scope)
      Next

      ForEach declareData\listDeclares()
         sName$       = declareData\listDeclares()\sName$
         sModuleName$ = declareData\listDeclares()\sModuleName$
         scope        = declareData\listDeclares()\Scope
         bKeep        = #False

         sKeyGlobal$ = BuildNameModuleScopeKey(sName$, "", #SCOPE_GLOBAL)
         sKeyDM$     = BuildNameModuleScopeKey(sName$, sModuleName$, #SCOPE_DECLAREMODULE)
         sKeyModule$ = BuildNameModuleScopeKey(sName$, sModuleName$, #SCOPE_MODULE)
         sKeyCompilerIf$ = BuildNameModuleScopeKey(sName$, "", #SCOPE_COMPILER_IF)

         Select scope
            Case #SCOPE_GLOBAL
               If ListHasLine(listProcKeys$(), sKeyGlobal$)
                  bKeep = #True
               EndIf

            Case #SCOPE_DECLAREMODULE
               If ListHasLine(listProcKeys$(), sKeyDM$)
                  bKeep = #True
               ElseIf ListHasLine(listProcKeys$(), sKeyModule$)
                  bKeep = #True
               EndIf

            Case #SCOPE_MODULE
               If ListHasLine(listDeclKeys$(), sKeyDM$)
                  bKeep = #False
               ElseIf ListHasLine(listProcKeys$(), sKeyModule$)
                  bKeep = #True
               EndIf

            Case #SCOPE_COMPILER_IF
               If ListHasLine(listProcKeys$(), sKeyCompilerIf$)
                  bKeep = #True
               EndIf
         EndSelect

         If bKeep = #False
            AddJob_DeleteDeclare_Safe(declareData\listDeclares()\LineNr, sName$, scope, sModuleName$)
         EndIf
      Next
   EndProcedure

   Procedure BuildJobs_SpecialModulePass_DM_WinsAlways()
      Shared declareData

      Protected sName$
      Protected sModuleName$
      Protected sKeyDM$

      Protected NewList listDeclKeys$()

      ClearList(listDeclKeys$())

      ForEach declareData\listDeclares()
         AddElement(listDeclKeys$())
         listDeclKeys$() = BuildNameModuleScopeKey(declareData\listDeclares()\sName$, declareData\listDeclares()\sModuleName$, declareData\listDeclares()\Scope)
      Next

      ForEach declareData\listDeclares()
         If declareData\listDeclares()\Scope = #SCOPE_MODULE
            sName$       = declareData\listDeclares()\sName$
            sModuleName$ = declareData\listDeclares()\sModuleName$
            sKeyDM$      = BuildNameModuleScopeKey(sName$, sModuleName$, #SCOPE_DECLAREMODULE)

            If ListHasLine(listDeclKeys$(), sKeyDM$)
               AddJob_DeleteDeclare_Safe(declareData\listDeclares()\LineNr, sName$, #SCOPE_MODULE, sModuleName$)
            EndIf
         EndIf
      Next
   EndProcedure

   Procedure BuildJobList()
      Shared listJobs()

      ClearList(listJobs())
      BuildJobs_DeleteDuplicateDeclares()
      BuildJobs_GenerateMissingDeclares()
      BuildJobs_DeleteOrphanDeclares()
      BuildJobs_SpecialModulePass_DM_WinsAlways()
   EndProcedure

   Procedure.s BuildDeclareLineFromJob(sName$, bUseIndent.b)
      Shared options
      Protected sLine$

      If Left(sName$, 1) = "."
         sLine$ = "Declare" + sName$
      Else
         sLine$ = "Declare " + sName$
      EndIf
      If bUseIndent
         sLine$ = options\sIndent$ + sLine$
      EndIf
      sLine$ + " ; ADDED BY AUTO_DECLARE"

      ProcedureReturn sLine$
   EndProcedure

   Procedure.b ApplyJobsToSourceByRef(List listSourceLines$())
      Shared listJobs()
      Shared declareData
      Shared options
      Protected NewList listTargetLines$()
      Protected NewMap mapDelete.i()
      Protected NewMap mapInsert.s()
      Protected lineNr.q = 0
      Protected i
      Protected n
      Protected key$

      If ListSize(listJobs()) = 0
         ProcedureReturn #False
      EndIf

      declareData\bSourceChanged = #True

      ; DELETE MAP
      ForEach listJobs()
         If listJobs()\JobType = #JOB_DELETE_DECLARE
            mapDelete(Str(listJobs()\DeleteLine)) = 1
         EndIf
      Next

      ; INSERT MAP
      ForEach listJobs()
         If listJobs()\JobType = #JOB_GENERATE_DECLARE

            key$ = Str(listJobs()\InsertLine)

            If FindMapElement(mapInsert(), key$) = 0
               mapInsert(key$) = ""
            EndIf

            If mapInsert() <> ""
               mapInsert() + Chr(10)
            EndIf
            mapInsert() + BuildDeclareLineFromJob(listJobs()\sName$, listJobs()\UseIndent)
         EndIf
      Next

      ; RENDER
      ForEach listSourceLines$()
         lineNr + 1

         If FindMapElement(mapInsert(), Str(lineNr))
            If mapInsert() <> ""
               For i = 1 To options\aBlankLinesBeforeDeclareBlock
                  AddElement(listTargetLines$())
                  listTargetLines$() = "" ; Adds blank lines
               Next

               n = CountString(mapInsert(), Chr(10)) + 1
               For i = 1 To n
                  AddElement(listTargetLines$())
                  listTargetLines$() = StringField(mapInsert(), i, Chr(10))
               Next

               For i = 1 To options\aBlankLinesAfterDeclareBlock
                  AddElement(listTargetLines$())
                  listTargetLines$() = "" ; Adds blank lines
               Next
            EndIf
         EndIf

         If FindMapElement(mapDelete(), Str(lineNr)) = 0
            AddElement(listTargetLines$())
            listTargetLines$() = listSourceLines$()
         EndIf
      Next

      ClearList(listSourceLines$())

      ForEach listTargetLines$()
         AddElement(listSourceLines$())
         listSourceLines$() = listTargetLines$()
      Next

      ProcedureReturn #True
   EndProcedure


   Procedure.q GetFirstGlobalInsertLine()
      Shared declareData
      Protected qStart.q
      Protected qEnable.q

      ForEach declareData\listScopes()
         If declareData\listScopes()\ScopeType = #SCOPE_GLOBAL
            qStart  = declareData\listScopes()\StartLine
            qEnable = declareData\listScopes()\EnableExplicitLine
            If qEnable > 0
               ProcedureReturn qEnable + 1
            Else
               ProcedureReturn qStart + 1
            EndIf
         EndIf
      Next

      ProcedureReturn 1
   EndProcedure

   Procedure.b WriteSourceFile(strSourceFile$, List listSourceLines$())
      Shared options
      Protected qFile.q

      qFile = CreateFile(#PB_Any, strSourceFile$, options\qSourceEncoding)
      If qFile = 0
         MessageRequester("PreCompiler Error", "Could not overwrite file:" + #CRLF$ + strSourceFile$, #PB_MessageRequester_Error)
         ProcedureReturn #False
      EndIf

      If options\bSourceHasBOM = #True
         WriteStringFormat(qFile, options\qSourceEncoding)
      EndIf

      ForEach listSourceLines$()
         WriteStringN(qFile, listSourceLines$(), options\qSourceEncoding)
      Next
      CloseFile(qFile)

      ProcedureReturn #True
   EndProcedure

   Procedure.b ProcedureExists(name$, sModuleName$, scope.q)
      Shared declareData

      ForEach declareData\listProcedures()
         If declareData\listProcedures()\sName$ = name$
            If declareData\listProcedures()\sModuleName$ = sModuleName$
               If declareData\listProcedures()\Scope = scope
                  ProcedureReturn #True
               EndIf
            EndIf
         EndIf
      Next

      ProcedureReturn #False
   EndProcedure

   Procedure.b DeclareExists(name$, sModuleName$, scope.q)
      Shared declareData

      ForEach declareData\listDeclares()
         If declareData\listDeclares()\sName$ = name$
            If declareData\listDeclares()\sModuleName$ = sModuleName$
               If declareData\listDeclares()\Scope = scope
                  ProcedureReturn #True
               EndIf
            EndIf
         EndIf
      Next

      ProcedureReturn #False
   EndProcedure

   Procedure.q GetDuplicateLinesFromListByRef(List listInputByRef$(), List listResultByRef$())
      Protected NewMap mapSeen.q()
      Protected NewMap mapDuplicateAdded.b()
      Protected sKey$
      Protected qRemoved.q = 0

      ClearList(listResultByRef$())

      ForEach listInputByRef$()
         sKey$ = listInputByRef$()

         If FindMapElement(mapSeen(), sKey$) = 0
            mapSeen(sKey$) = 1
         Else
            qRemoved + 1
            If FindMapElement(mapDuplicateAdded(), sKey$) = 0
               AddElement(listResultByRef$())
               listResultByRef$()       = sKey$
               mapDuplicateAdded(sKey$) = #True
            EndIf
         EndIf
      Next

      ProcedureReturn qRemoved
   EndProcedure

EndModule

;- CompilerIf

CompilerIf #PB_Compiler_IsMainFile

   Mod_PreProcessor_AutoDeclare::Init()

CompilerEndIf