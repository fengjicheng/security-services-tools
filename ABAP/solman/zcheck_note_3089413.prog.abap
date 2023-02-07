*&---------------------------------------------------------------------*
*& Report  ZCHECK_NOTE_3089413
*& Check implementation status of note 3089413 for connected ABAP systems
*&---------------------------------------------------------------------*
*& Author: Frank Buchholz, SAP CoE Security Services
*& Source: https://github.com/SAP-samples/security-services-tools
*&
*& 07.02.2023 Show trusted systems without any data in RFCSYSACL
*&            Show mutual trust relations
*& 06.02.2023 New result field to indicate explicit selftrust defined in SMT1
*&            A double click on a count of trusted systems shows a popup with the details
*& 02.02.2023 Check destinations, too
*& 02.02.2023 Initial version
*&---------------------------------------------------------------------*
REPORT ZCHECK_NOTE_3089413.

CONSTANTS: c_program_version(30) TYPE c VALUE '07.02.2023 FBT'.

type-pools: ICON, COL, SYM.

DATA sel_store_dir TYPE sdiagst_store_dir.

* System name
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(30) ss_sid FOR FIELD p_sid.
SELECT-OPTIONS p_sid   FOR sel_store_dir-long_sid.
SELECTION-SCREEN END OF LINE.

* Check Kernel
selection-screen begin of line.
parameters       P_KERN as checkbox default 'X'.
selection-screen comment 3(33) PS_KERN for field P_KERN.
selection-screen end of line.

* Check ABAP
selection-screen begin of line.
parameters       P_ABAP as checkbox default 'X'.
selection-screen comment 3(33) PS_ABAP for field P_ABAP.
selection-screen end of line.

* Check trusted relations
selection-screen begin of line.
parameters       P_TRUST as checkbox default 'X'.
selection-screen comment 3(33) PS_TRUST for field P_TRUST.
selection-screen end of line.

* Check trusted destinations
selection-screen begin of line.
parameters       P_DEST as checkbox default 'X'.
selection-screen comment 3(33) PS_DEST for field P_DEST.
selection-screen end of line.
* Show specific type only if data found
data P_DEST_3 type abap_bool.
data P_DEST_H type abap_bool.
data P_DEST_W type abap_bool.

* Store status
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(30) ss_state FOR FIELD p_state.
SELECT-OPTIONS p_state FOR sel_store_dir-store_main_state_type." DEFAULT 'G'.
SELECTION-SCREEN END OF LINE.

* Layout of ALV output
selection-screen begin of line.
selection-screen comment 1(33) PS_LOUT for field P_LAYOUT.
parameters       P_LAYOUT type DISVARIANT-VARIANT.
selection-screen end of line.

SELECTION-SCREEN COMMENT /1(60) ss_vers.

*----------------------------------------------------------------------

TYPES:
  BEGIN OF ts_result,
    " Assumption: Match entries from different stores based on install_number and landscape_id

    install_number        TYPE sdiagst_store_dir-install_number,

    long_sid              TYPE diagls_tech_syst_long_sid,    "sdiagst_store_dir-long_sid,
    sid                   TYPE diagls_technical_system_sid,  "sdiagst_store_dir-sid,
    tech_system_type      TYPE diagls_technical_system_type, "sdiagst_store_dir-tech_system_type,
    tech_system_id        TYPE diagls_id,                    "sdiagst_store_dir-tech_system_id,
    landscape_id          TYPE diagls_id,                    "sdiagst_store_dir-landscape_id,
    host_full             TYPE diagls_host_full_name,        "sdiagst_store_dir-host_full,
    host                  TYPE diagls_host_name,             "sdiagst_store_dir-host,
    host_id               TYPE diagls_id,                    "sdiagst_store_dir-host_id,
    physical_host         TYPE diagls_host_name,             "sdiagst_store_dir-physical_host,
    instance_type         TYPE diagls_instance_type,         "sdiagst_store_dir-instance_type,
    instance              TYPE diagls_instance_name,         "sdiagst_store_dir-instance,

    " Source store: we show the status of the first found store only which is usually store SAP_KERNEL
    compv_name            TYPE sdiagst_store_dir-compv_name,

    " Source store: SAP_KERNEL
    kern_rel              TYPE string,                               " 722_EXT_REL
    kern_patchlevel       TYPE string,                               " 1000
    kern_comp_time        TYPE string,                               " Jun  7 2020 15:44:10
    kern_comp_date        TYPE sy-datum,

    validate_kernel       TYPE string,

    " Source store: ABAP_COMP_SPLEVEL
    ABAP_RELEASE          TYPE string,                               " 754
    ABAP_SP               TYPE string,                               " 0032

    validate_ABAP         TYPE string,

    " Source store: ABAP_NOTES
    NOTE_3089413          TYPE string,
    NOTE_3089413_PRSTATUS TYPE CWBPRSTAT,
    NOTE_3287611          TYPE string,
    NOTE_3287611_PRSTATUS TYPE CWBPRSTAT,

    " Source store: RFCSYSACL
    TRUSTSY_cnt_all       TYPE i,
    NO_DATA_CNT           TYPE i,
    MUTUAL_TRUST_CNT      TYPE i,
    TRUSTSY_CNT_TCD       TYPE i,
    TRUSTSY_cnt_3         TYPE i,
    TRUSTSY_cnt_2         TYPE i,
    TRUSTSY_cnt_1         TYPE i,
    EXPLICIT_SELFTRUST    TYPE string,

    " Source store: ABAP_INSTANMCE_PAHI
    RFC_SELFTRUST         TYPE string,
    rfc_allowoldticket4tt TYPE string,
    rfc_sendInstNr4tt     TYPE string,

    " Source store: RFCDES
    DEST_3_cnt_all               TYPE i,
    DEST_3_cnt_trusted           TYPE i,
    DEST_3_cnt_trusted_migrated  TYPE i,
    DEST_3_cnt_trusted_no_instnr TYPE i,
    DEST_3_cnt_trusted_no_sysid  TYPE i,
    DEST_3_cnt_trusted_snc       TYPE i,

    DEST_H_cnt_all               TYPE i,
    DEST_H_cnt_trusted           TYPE i,
    DEST_H_cnt_trusted_migrated  TYPE i,
    DEST_H_cnt_trusted_no_instnr TYPE i,
    DEST_H_cnt_trusted_no_sysid  TYPE i,
    DEST_H_cnt_trusted_tls       TYPE i,

    DEST_W_cnt_all               TYPE i,
    DEST_W_cnt_trusted           TYPE i,
    DEST_W_cnt_trusted_migrated  TYPE i,
    DEST_W_cnt_trusted_no_instnr TYPE i,
    DEST_W_cnt_trusted_no_sysid  TYPE i,
    DEST_W_cnt_trusted_tls       TYPE i,

    " Source store: we show the status of the first found store only which is usually store SAP_KERNEL
    store_id              TYPE sdiagst_store_dir-store_id,
    store_last_upload     TYPE sdiagst_store_dir-store_last_upload,
    store_state           TYPE sdiagst_store_dir-store_state,           " CMPL = ok
    store_main_state_type TYPE sdiagst_store_dir-store_main_state_type, " (G)reen, (Y)ello, (R)ed, (N)ot relevant
    store_main_state      TYPE sdiagst_store_dir-store_main_state,
    store_outdated_day    TYPE sdiagst_store_dir-store_outdated_day,

    t_color               type lvc_t_scol,
*   t_celltype             type salv_t_int4_column,
*   T_HYPERLINK            type SALV_T_INT4_COLUMN,
*   t_dropdown             type salv_t_int4_column,
  END OF ts_result,
  tt_result TYPE TABLE OF ts_result.

DATA:
  lt_result TYPE tt_result,
  ls_result TYPE ts_result.

data: GS_ALV_LOUT_VARIANT type DISVARIANT.

" Popup showing trusted systems
types:
  begin of ts_RFCSYSACL_data,
    RFCSYSID    type RFCSSYSID,  " Trusted system
    TLICENSE_NR type SLIC_INST,  " Installation number of trusted system

    RFCTRUSTSY  type RFCSSYSID,  " Trusting system (=current system)
    LLICENSE_NR type SLIC_INST,  " Installation number of trusting system (=current system), only available in higher versions

    RFCDEST     type RFCDEST,    " Destination to trusted system
    RFCCREDEST  type RFCDEST,    " Destination, only available in higher versions
    RFCREGDEST  type RFCDEST,    " Destination, only available in higher versions

    RFCSNC      type RFCSNC,     " SNC respective TLS
    RFCSECKEY   type RFCTICKET,  " Security key (empty or '(stored)'), only available in higher versions
    RFCTCDCHK   type RFCTCDCHK,  " Tcode check
    RFCSLOPT    type RFCSLOPT,   " Options respective version

    NO_DATA      type string,    " No data found for trusted system
    MUTUAL_TRUST type string,    " Mutual trus relation

    t_color               type lvc_t_scol,
  end of ts_RFCSYSACL_data,
  tt_RFCSYSACL_data type STANDARD TABLE OF ts_RFCSYSACL_data WITH KEY RFCSYSID TLICENSE_NR,

  begin of ts_TRUSTED_SYSTEM,
    RFCTRUSTSY  type RFCSSYSID,  " Trusting system (=current system)
    LLICENSE_NR type SLIC_INST,  " Installation number of trusting system
    RFCSYSACL_data type tt_RFCSYSACL_data,
  end of ts_TRUSTED_SYSTEM,
  tt_TRUSTED_SYSTEMS type STANDARD TABLE OF ts_TRUSTED_SYSTEM WITH KEY RFCTRUSTSY LLICENSE_NR.

data:
  ls_TRUSTED_SYSTEM  type ts_TRUSTED_SYSTEM,
  lt_TRUSTED_SYSTEMS type tt_TRUSTED_SYSTEMS.

*----------------------------------------------------------------------

INITIALIZATION.
  sy-title = 'Check implementation status of note 3089413 for connected ABAP systems'(TIT).

  ss_sid   = 'System'.
  ss_state = 'Config. store status (G/Y/R)'.

  PS_KERN  = 'Check Kernel'.
  PS_ABAP  = 'Check Support Package and Notes'.
  PS_TRUST = 'Check Trusted Relations'.
  PS_DEST  = 'Check Trusted Destinations'.

  PS_LOUT     = 'Layout'(t18).

  CONCATENATE 'Program version:'(ver) c_program_version INTO ss_vers
     SEPARATED BY space.

*----------------------------------------------------------------------

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sid-low.
  PERFORM f4_sid USING 'P_SID-LOW'.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sid-high.
  PERFORM f4_sid USING 'P_SID-HIGH'.

*
FORM f4_sid USING l_dynprofield  TYPE help_info-dynprofld.

  DATA: "dynpro_values TYPE TABLE OF dynpread,
    "field_value   LIKE LINE OF dynpro_values,
    "field_tab     TYPE TABLE OF dfies  WITH HEADER LINE,
    BEGIN OF value_tab OCCURS 0,
      long_sid       TYPE diagls_tech_syst_long_sid,    "sdiagst_store_dir-long_sid,
      "sid                   TYPE diagls_technical_system_sid,  "sdiagst_store_dir-sid,
      "tech_system_id        TYPE diagls_id,                    "sdiagst_store_dir-tech_system_id,
      install_number TYPE diagls_tech_syst_install_nbr,
      itadmin_role   TYPE diagls_itadmin_role,
    END OF value_tab.

  DATA(progname) = sy-repid.
  DATA(dynnum)   = sy-dynnr.

  DATA:
    lt_technical_systems TYPE  tt_diagst_tech_syst,
    rc                   TYPE  i,
    rc_text              TYPE  natxt.

  CALL FUNCTION 'DIAGST_GET_TECH_SYSTEMS'
    EXPORTING
      namespace         = 'ACTIVE'
*     LONG_SID          =
      tech_type         = 'ABAP'
*     INSTALL_NUMBER    =
*     TECH_SYST_ID      =
*     DIAG_RELEVANT     = 'X'
*     STATS_FROM        =
*     STATS_TO          =
*     DISPLAY           = ' '                        " Only useful if the function is manually executed by transaction SE37.
                                                     " Setting this parameter to �X� will display the result.
*     CALLING_APPL      = ' '
    IMPORTING
      technical_systems = lt_technical_systems
*     STATS             =
      rc                = rc
      rc_text           = rc_text.

  LOOP AT lt_technical_systems INTO DATA(ls_technical_systems).
    MOVE-CORRESPONDING ls_technical_systems TO value_tab.
    APPEND value_tab.
  ENDLOOP.
  SORT value_tab BY long_sid.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LONG_SID'
      dynpprog        = progname
      dynpnr          = dynnum
      dynprofield     = l_dynprofield
      value_org       = 'S'
    TABLES
*     field_tab       = field_tab
      value_tab       = value_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM. "F4_SID

*----------------------------------------------------------------------*
*  AT SELECTION-SCREEN ON p_layout
*----------------------------------------------------------------------*

at selection-screen on P_LAYOUT.
  check not P_LAYOUT is initial.
  perform HANDLE_AT_SELSCR_ON_P_LAYOUT using P_LAYOUT SY-REPID 'A'.
*
form HANDLE_AT_SELSCR_ON_P_LAYOUT
   using ID_VARNAME type DISVARIANT-VARIANT
         ID_REPID   type SY-REPID
         ID_SAVE    type C.

  data: LS_VARIANT type DISVARIANT.

  LS_VARIANT-REPORT  = ID_REPID.
  LS_VARIANT-VARIANT = ID_VARNAME.

  call function 'REUSE_ALV_VARIANT_EXISTENCE'
    exporting
      I_SAVE        = ID_SAVE
    changing
      CS_VARIANT    = LS_VARIANT
    exceptions
      WRONG_INPUT   = 1
      NOT_FOUND     = 2
      PROGRAM_ERROR = 3
      others        = 4.

  if SY-SUBRC <> 0.
*   Selected layout variant is not found
    message E204(0K).
  endif.

  GS_ALV_LOUT_VARIANT-REPORT  = ID_REPID.
  GS_ALV_LOUT_VARIANT-VARIANT = ID_VARNAME.

endform.                    " handle_at_selscr_on_p_layout

*----------------------------------------------------------------------*
*  AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_layout
*----------------------------------------------------------------------*
at selection-screen on value-request for P_LAYOUT.  " ( Note 890141 )
  perform HANDLE_AT_SELSCR_F4_P_LAYOUT using    SY-REPID 'A'
                                       changing P_LAYOUT.
*
form HANDLE_AT_SELSCR_F4_P_LAYOUT
  using    ID_REPID   type SY-REPID
           ID_SAVE    type C
  changing ED_VARNAME type DISVARIANT-VARIANT.

  GS_ALV_LOUT_VARIANT-REPORT = ID_REPID.

  call function 'REUSE_ALV_VARIANT_F4'
    exporting
      IS_VARIANT    = GS_ALV_LOUT_VARIANT
      I_SAVE        = ID_SAVE
    importing
      ES_VARIANT    = GS_ALV_LOUT_VARIANT
    exceptions
      NOT_FOUND     = 1
      PROGRAM_ERROR = 2
      others        = 3.

  if SY-SUBRC = 0.
    ED_VARNAME = GS_ALV_LOUT_VARIANT-VARIANT.
  else.
    message S073(0K).
*   Keine Anzeigevariante(n) vorhanden
  endif.

endform.                               " handle_at_selscr_f4_p_layout

*----------------------------------------------------------------------

START-OF-SELECTION.

  PERFORM get_SAP_KERNEL.         " Kernel version
  PERFORM get_ABAP_COMP_SPLEVEL.  " Support Package version of SAP_BASIS
  PERFORM get_ABAP_NOTES.         " Notes 3089413 and 3287611
  PERFORM get_RFCSYSACL.          " Trusting relations
  PERFORM get_RFCDES.             " Trusted desinations
  PERFORM get_ABAP_INSTANCE_PAHI. " rfc/selftrust

  PERFORM validate_kernel.
  PERFORM validate_ABAP.

  PERFORM validate_mutual_trust.

  PERFORM show_result.

*----------------------------------------------------------------------

FORM get_SAP_KERNEL.
  check P_KERN = 'X'.

  " Same as in report ZSHOW_KERNEL_STORES but one one entry per system

  DATA:
    lt_store_dir_tech    TYPE  tt_diagst_store_dir_tech,
    lt_store_dir         TYPE  tt_diagst_store_dir,
    lt_fieldlist         TYPE  tt_diagst_table_store_fields,
    lt_snapshot          TYPE  tt_diagst_trows,
    rc                   TYPE  i,
    rc_text              TYPE  natxt.

  data: tabix type i.

  CALL FUNCTION 'DIAGST_GET_STORES'
    EXPORTING

      " The �System Filter� parameters allow to get all Stores of a system or technical system.
      " Some combinations of the four parameters are not allowed.
      " The function will return an error code in such a case.
*     SID                   = ' '
*     INSTALL_NUMBER        = ' '
*     LONG_SID              = ' '
*     TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)

      " Store key fields
      group_namespace       = 'ACTIVE'                   "(optional)
      group_landscape_class = 'CL_DIAGLS_ABAP_INSTANCE'  "(optional)
*     GROUP_LANDSCAPE_ID    = ' '
*     GROUP_COMP_ID         = ' '
      group_source          = 'ABAP'                     "(optional)
      group_name            = 'INSTANCE'                 "(optional)
      store_category        = 'SOFTWARE'                 "(optional)
      store_type            = 'PROPERTY'                 "(optional)
*     STORE_FULLPATH        = ' '
      store_name            = 'SAP_KERNEL'

      " Special filters
      store_mainalias       = 'ABAP-SOFTWARE'            "(optional)
      store_subalias        = 'SAP-KERNEL'               "(optional)
*     STORE_TPL_ID          = ' '
*     HAS_ELEMENT_FROM      =                            " date range
*     HAS_ELEMENT_TO        =                            " date range
*     ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*     CASE_INSENSITIVE      = ' '
*     PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*     SEARCH_STRING         =
*     ONLY_RELEVANT         = 'X'
*     PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll

      " Others
*     DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
                                                         " Setting this parameter to �X� will display the result.
*     CALLING_APPL          = ' '

    IMPORTING
*     STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
      store_dir             = lt_store_dir               "(not recommended anymore)
*     STORE_DIR_MI          =                            "(SAP internal usage only)
*     STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*     PARAMETER             =                            "(SAP internal usage only)
      rc                    = rc
      rc_text               = rc_text.

  IF rc IS NOT INITIAL.
    MESSAGE e001(00) WITH rc_text.
  ENDIF.

  LOOP AT lt_store_dir INTO data(ls_store_dir)
    WHERE long_sid              IN p_sid
      AND store_main_state_type IN p_state
    .

    " Do we already have an entry for this system?
    READ table lt_result into ls_result
      with key
        install_number = ls_store_dir-install_number
        long_sid       = ls_store_dir-long_sid
        sid            = ls_store_dir-sid
        .
    if sy-subrc = 0.
      tabix = sy-tabix.
      if ls_store_dir-instance_type ne 'CENTRAL'.
        continue.
      endif.
      MOVE-CORRESPONDING ls_store_dir TO ls_result.
    else.
      tabix = -1.
      CLEAR ls_result.
      MOVE-CORRESPONDING ls_store_dir TO ls_result.
    endif.

    IF ls_result-host_full IS INITIAL.
      ls_result-host_full = ls_result-host. " host, host_id, physical_host
    ENDIF.

    CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
      EXPORTING
        store_id                    = ls_store_dir-store_id
*       TIMESTAMP                   =                        " if not specified the latest available snapshot is returned
*       CALLING_APPL                = ' '
      IMPORTING
        fieldlist                   = lt_fieldlist
*       SNAPSHOT_VALID_FROM         =
*       SNAPSHOT_VALID_TO_CONFIRMED =
*       SNAPSHOT_VALID_TO           =
        snapshot                    = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*       SNAPSHOT_TR                 =
*       SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
        rc                          = rc                     " 3: Permission denied, Content Authorization missing
                                                             " 4: Store not existing
                                                             " 8: Error
        rc_text                     = rc_text.

    LOOP AT lt_snapshot INTO data(lt_snapshot_elem).
      READ TABLE lt_snapshot_elem INTO data(ls_PARAMETER) INDEX 1.
      check ls_PARAMETER-fieldname = 'PARAMETER'.

      READ TABLE lt_snapshot_elem INTO data(ls_VALUE)     INDEX 2.
      check ls_VALUE-fieldname = 'VALUE'.

      CASE ls_PARAMETER-fieldvalue.

        WHEN 'KERN_COMP_ON'.      " Linux GNU SLES-11 x86_64 cc4.3.4 use-pr190909
          " not used yet

        WHEN 'KERN_COMP_TIME'.    " Jun  7 2020 15:44:10
          ls_result-kern_comp_time  = ls_VALUE-fieldvalue.
          PERFORM convert_comp_time USING ls_result-kern_comp_time CHANGING ls_result-kern_comp_date.

        WHEN 'KERN_DBLIB'.        " SQLDBC 7.9.8.040
          " not used yet

        WHEN 'KERN_PATCHLEVEL'.   " 1000
          ls_result-kern_patchlevel = ls_VALUE-fieldvalue.

        WHEN 'KERN_REL'.          " 722_EXT_REL
          ls_result-kern_rel        = ls_VALUE-fieldvalue.

        WHEN 'PLATFORM-ID'.       " 390
          " not used yet

      ENDCASE.
    ENDLOOP.

    if tabix > 0.
      MODIFY lt_result from ls_result INDEX tabix.
    else.
      APPEND ls_result TO lt_result.
    endif.

  ENDLOOP. " lt_STORE_DIR

ENDFORM. " get_SAP_KERNEL

FORM get_ABAP_COMP_SPLEVEL.
  check P_ABAP = 'X'.

  DATA:
    lt_store_dir_tech    TYPE  tt_diagst_store_dir_tech,
    lt_store_dir         TYPE  tt_diagst_store_dir,
    lt_fieldlist         TYPE  tt_diagst_table_store_fields,
    lt_snapshot          TYPE  tt_diagst_trows,
    rc                   TYPE  i,
    rc_text              TYPE  natxt.

  data: tabix type i.

  " Using a SEARCH_STRING for SAP_BASIS should not speed up processing, as this component exists always
  CALL FUNCTION 'DIAGST_GET_STORES'
    EXPORTING

      " The �System Filter� parameters allow to get all Stores of a system or technical system.
      " Some combinations of the four parameters are not allowed.
      " The function will return an error code in such a case.
*     SID                   = ' '
*     INSTALL_NUMBER        = ' '
*     LONG_SID              = ' '
*     TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)

      " Store key fields
      group_namespace       = 'ACTIVE'                   "(optional)
      group_landscape_class = 'CL_DIAGLS_ABAP_TECH_SYST' "(optional)
*     GROUP_LANDSCAPE_ID    = ' '
*     GROUP_COMP_ID         = ' '
      group_source          = 'ABAP'                     "(optional)
      group_name            = 'ABAP-SOFTWARE'            "(optional)
      store_category        = 'SOFTWARE'                 "(optional)
      store_type            = 'TABLE'                    "(optional)
*     STORE_FULLPATH        = ' '
      store_name            = 'ABAP_COMP_SPLEVEL'

      " Special filters
      store_mainalias       = 'ABAP-SOFTWARE'            "(optional)
      store_subalias        = 'SUPPORT-PACKAGE-LEVEL'    "(optional)
*     STORE_TPL_ID          = ' '
*     HAS_ELEMENT_FROM      =                            " date range
*     HAS_ELEMENT_TO        =                            " date range
*     ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*     CASE_INSENSITIVE      = ' '
      "PATTERN_SEARCH        = ' '                        " Allow pattern search for SEARCH_STRING
      "SEARCH_STRING         = 'SAP_BASIS'
*     ONLY_RELEVANT         = 'X'
*     PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll

      " Others
*     DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
                                                         " Setting this parameter to �X� will display the result.
*     CALLING_APPL          = ' '

    IMPORTING
*     STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
      store_dir             = lt_store_dir               "(not recommended anymore)
*     STORE_DIR_MI          =                            "(SAP internal usage only)
*     STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*     PARAMETER             =                            "(SAP internal usage only)
      rc                    = rc
      rc_text               = rc_text.

  IF rc IS NOT INITIAL.
    MESSAGE e001(00) WITH rc_text.
  ENDIF.

  LOOP AT lt_store_dir INTO data(ls_store_dir)
    WHERE long_sid              IN p_sid
      AND store_main_state_type IN p_state
    .

    " Do we already have an entry for this system?
    READ table lt_result into ls_result
      with key
        install_number = ls_store_dir-install_number
        long_sid       = ls_store_dir-long_sid
        sid            = ls_store_dir-sid
        .
    if sy-subrc = 0.
      tabix = sy-tabix.
    else.
      tabix = -1.
      CLEAR ls_result.
      MOVE-CORRESPONDING ls_store_dir TO ls_result.
    endif.

    CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
      EXPORTING
        store_id                    = ls_store_dir-store_id
*       TIMESTAMP                   =                        " if not specified the latest available snapshot is returned
*       CALLING_APPL                = ' '
      IMPORTING
        fieldlist                   = lt_fieldlist
*       SNAPSHOT_VALID_FROM         =
*       SNAPSHOT_VALID_TO_CONFIRMED =
*       SNAPSHOT_VALID_TO           =
        snapshot                    = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*       SNAPSHOT_TR                 =
*       SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
        rc                          = rc                     " 3: Permission denied, Content Authorization missing
                                                             " 4: Store not existing
                                                             " 8: Error
        rc_text                     = rc_text.

    LOOP AT lt_snapshot INTO data(lt_snapshot_elem).
      READ TABLE lt_snapshot_elem INTO data(ls_COMPONENT)  INDEX 1.
      check ls_COMPONENT-fieldname = 'COMPONENT'.
      check ls_COMPONENT-fieldvalue = 'SAP_BASIS'.

      READ TABLE lt_snapshot_elem INTO data(ls_RELEASE)    INDEX 2.
      check ls_RELEASE-fieldname = 'RELEASE'.
      ls_result-ABAP_RELEASE = ls_RELEASE-fieldvalue.

      READ TABLE lt_snapshot_elem INTO data(ls_EXTRELEASE) INDEX 3.
      check ls_EXTRELEASE-fieldname = 'EXTRELEASE'.
      ls_result-ABAP_SP      = ls_EXTRELEASE-fieldvalue.
    ENDLOOP.

    if tabix > 0.
      MODIFY lt_result from ls_result INDEX tabix.
    else.
      APPEND ls_result TO lt_result.
    endif.

  ENDLOOP. " lt_STORE_DIR

ENDFORM. " get_ABAP_COMP_SPLEVEL

FORM get_ABAP_NOTES.
  check P_ABAP = 'X'.

  DATA:
    lt_store_dir_tech    TYPE  tt_diagst_store_dir_tech,
    lt_store_dir         TYPE  tt_diagst_store_dir,
    lt_fieldlist         TYPE  tt_diagst_table_store_fields,
    lt_snapshot          TYPE  tt_diagst_trows,
    rc                   TYPE  i,
    rc_text              TYPE  natxt.

  data: tabix type i.

  " Maybe it' faster to call it twice including a SEARCH_STRING for both note numbers.
  CALL FUNCTION 'DIAGST_GET_STORES'
    EXPORTING

      " The �System Filter� parameters allow to get all Stores of a system or technical system.
      " Some combinations of the four parameters are not allowed.
      " The function will return an error code in such a case.
*     SID                   = ' '
*     INSTALL_NUMBER        = ' '
*     LONG_SID              = ' '
*     TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)

      " Store key fields
      group_namespace       = 'ACTIVE'                   "(optional)
      group_landscape_class = 'CL_DIAGLS_ABAP_TECH_SYST' "(optional)
*     GROUP_LANDSCAPE_ID    = ' '
*     GROUP_COMP_ID         = ' '
      group_source          = 'ABAP'                     "(optional)
      group_name            = 'ABAP-SOFTWARE'            "(optional)
      store_category        = 'SOFTWARE'                 "(optional)
      store_type            = 'TABLE'                    "(optional)
*     STORE_FULLPATH        = ' '
      store_name            = 'ABAP_NOTES'

      " Special filters
      store_mainalias       = 'ABAP-SOFTWARE'            "(optional)
      store_subalias        = 'ABAP-NOTES'               "(optional)
*     STORE_TPL_ID          = ' '
*     HAS_ELEMENT_FROM      =                            " date range
*     HAS_ELEMENT_TO        =                            " date range
*     ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*     CASE_INSENSITIVE      = ' '
*     PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*     SEARCH_STRING         =
*     ONLY_RELEVANT         = 'X'
*     PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll

      " Others
*     DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
                                                         " Setting this parameter to �X� will display the result.
*     CALLING_APPL          = ' '

    IMPORTING
*     STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
      store_dir             = lt_store_dir               "(not recommended anymore)
*     STORE_DIR_MI          =                            "(SAP internal usage only)
*     STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*     PARAMETER             =                            "(SAP internal usage only)
      rc                    = rc
      rc_text               = rc_text.

  IF rc IS NOT INITIAL.
    MESSAGE e001(00) WITH rc_text.
  ENDIF.

  LOOP AT lt_store_dir INTO data(ls_store_dir)
    WHERE long_sid              IN p_sid
      AND store_main_state_type IN p_state
    .

    " Do we already have an entry for this system?
    READ table lt_result into ls_result
      with key
        install_number = ls_store_dir-install_number
        long_sid       = ls_store_dir-long_sid
        sid            = ls_store_dir-sid
        .
    if sy-subrc = 0.
      tabix = sy-tabix.
    else.
      tabix = -1.
      CLEAR ls_result.
      MOVE-CORRESPONDING ls_store_dir TO ls_result.
    endif.

    CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
      EXPORTING
        store_id                    = ls_store_dir-store_id
*       TIMESTAMP                   =                        " if not specified the latest available snapshot is returned
*       CALLING_APPL                = ' '
      IMPORTING
        fieldlist                   = lt_fieldlist
*       SNAPSHOT_VALID_FROM         =
*       SNAPSHOT_VALID_TO_CONFIRMED =
*       SNAPSHOT_VALID_TO           =
        snapshot                    = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*       SNAPSHOT_TR                 =
*       SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
        rc                          = rc                     " 3: Permission denied, Content Authorization missing
                                                             " 4: Store not existing
                                                             " 8: Error
        rc_text                     = rc_text.

    LOOP AT lt_snapshot INTO data(lt_snapshot_elem).
      READ TABLE lt_snapshot_elem INTO data(ls_NOTE)      INDEX 1. "
      check ls_NOTE-fieldname = 'NOTE'.
      check ls_NOTE-fieldvalue = '0003089413'
         or ls_NOTE-fieldvalue = '0003287611'.

      READ TABLE lt_snapshot_elem INTO data(ls_VERSION)   INDEX 2. "
      check ls_VERSION-fieldname = 'VERSION'.

      "READ TABLE lt_snapshot_elem INTO data(ls_TEXT)      INDEX 3. "
      "check ls_TEXT-fieldname = 'TEXT'.

      READ TABLE lt_snapshot_elem INTO data(ls_PRSTATUST) INDEX 4. "
      check ls_PRSTATUST-fieldname = 'PRSTATUST'.

      READ TABLE lt_snapshot_elem INTO data(ls_PRSTATUS)  INDEX 5. "
      check ls_PRSTATUS-fieldname = 'PRSTATUS'.

      data(status) = ls_PRSTATUST-fieldvalue && ` version ` && ls_VERSION-fieldvalue.
      case ls_NOTE-fieldvalue.
        when '0003089413'.
          ls_result-NOTE_3089413 = status.
          ls_result-NOTE_3089413_PRSTATUS = ls_PRSTATUS-fieldvalue.
        when '0003287611'.
          ls_result-NOTE_3287611 = status.
          ls_result-NOTE_3287611_PRSTATUS = ls_PRSTATUS-fieldvalue.
      endcase.

    ENDLOOP.

    if tabix > 0.
      MODIFY lt_result from ls_result INDEX tabix.
    else.
      APPEND ls_result TO lt_result.
    endif.

  ENDLOOP. " lt_STORE_DIR

ENDFORM. " get_ABAP_NOTES

FORM get_RFCSYSACL.
  check P_TRUST = 'X'.

  DATA:
    lt_store_dir_tech    TYPE  tt_diagst_store_dir_tech,
    lt_store_dir         TYPE  tt_diagst_store_dir,
    lt_fieldlist         TYPE  tt_diagst_table_store_fields,
    lt_snapshot          TYPE  tt_diagst_trows,
    rc                   TYPE  i,
    rc_text              TYPE  natxt.

  data: tabix type i.

  CALL FUNCTION 'DIAGST_GET_STORES'
    EXPORTING

      " The �System Filter� parameters allow to get all Stores of a system or technical system.
      " Some combinations of the four parameters are not allowed.
      " The function will return an error code in such a case.
*     SID                   = ' '
*     INSTALL_NUMBER        = ' '
*     LONG_SID              = ' '
*     TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)

      " Store key fields
      group_namespace       = 'ACTIVE'                   "(optional)
      group_landscape_class = 'CL_DIAGLS_ABAP_TECH_SYST' "(optional)
*     GROUP_LANDSCAPE_ID    = ' '
*     GROUP_COMP_ID         = ' '
      group_source          = 'ABAP'                     "(optional)
      group_name            = 'ABAP-SECURITY'            "(optional)
      store_category        = 'CONFIG'                   "(optional)
      store_type            = 'TABLE'                    "(optional)
*     STORE_FULLPATH        = ' '
      store_name            = 'RFCSYSACL'

      " Special filters
      store_mainalias       = 'SECURITY'                 "(optional)
      store_subalias        = 'TRUSTED RFC'              "(optional)
*     STORE_TPL_ID          = ' '
*     HAS_ELEMENT_FROM      =                            " date range
*     HAS_ELEMENT_TO        =                            " date range
*     ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*     CASE_INSENSITIVE      = ' '
*     PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*     SEARCH_STRING         =
*     ONLY_RELEVANT         = 'X'
*     PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll

      " Others
*     DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
                                                         " Setting this parameter to �X� will display the result.
*     CALLING_APPL          = ' '

    IMPORTING
*     STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
      store_dir             = lt_store_dir               "(not recommended anymore)
*     STORE_DIR_MI          =                            "(SAP internal usage only)
*     STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*     PARAMETER             =                            "(SAP internal usage only)
      rc                    = rc
      rc_text               = rc_text.

  IF rc IS NOT INITIAL.
    MESSAGE e001(00) WITH rc_text.
  ENDIF.

  LOOP AT lt_store_dir INTO data(ls_store_dir)
    WHERE long_sid              IN p_sid
      AND store_main_state_type IN p_state
    .

    " Do we already have an entry for this system?
    READ table lt_result into ls_result
      with key
        install_number = ls_store_dir-install_number
        long_sid       = ls_store_dir-long_sid
        sid            = ls_store_dir-sid
        .
    if sy-subrc = 0.
      tabix = sy-tabix.
    else.
      tabix = -1.
      CLEAR ls_result.
      MOVE-CORRESPONDING ls_store_dir TO ls_result.
    endif.

    CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
      EXPORTING
        store_id                    = ls_store_dir-store_id
*       TIMESTAMP                   =                        " if not specified the latest available snapshot is returned
*       CALLING_APPL                = ' '
      IMPORTING
        fieldlist                   = lt_fieldlist
*       SNAPSHOT_VALID_FROM         =
*       SNAPSHOT_VALID_TO_CONFIRMED =
*       SNAPSHOT_VALID_TO           =
        snapshot                    = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*       SNAPSHOT_TR                 =
*       SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
        rc                          = rc                     " 3: Permission denied, Content Authorization missing
                                                             " 4: Store not existing
                                                             " 8: Error
        rc_text                     = rc_text.

    " Store RRFCSYSACL data
    clear ls_TRUSTED_SYSTEM.
    ls_TRUSTED_SYSTEM-RFCTRUSTSY  = ls_store_dir-sid.
    ls_TRUSTED_SYSTEM-LLICENSE_NR = ls_store_dir-install_number.

    LOOP AT lt_snapshot INTO data(lt_snapshot_elem).

    " Store RRFCSYSACL data
      data ls_RFCSYSACL_data type ts_RFCSYSACL_data.
      clear ls_RFCSYSACL_data.

      loop at lt_snapshot_elem into data(snapshot_elem).
        if snapshot_elem-fieldvalue = '<CCDB NULL>'.
          clear snapshot_elem-fieldvalue.
        endif.

        case snapshot_elem-fieldname.
          when 'RFCSYSID'.    ls_RFCSYSACL_data-RFCSYSID    = snapshot_elem-fieldvalue. " 1
          when 'TLICENSE_NR'. ls_RFCSYSACL_data-TLICENSE_NR = snapshot_elem-fieldvalue. " 2
          when 'RFCTRUSTSY'.  ls_RFCSYSACL_data-RFCTRUSTSY  = snapshot_elem-fieldvalue. " 3
          when 'RFCDEST'.     ls_RFCSYSACL_data-RFCDEST     = snapshot_elem-fieldvalue. " 4
          when 'RFCTCDCHK'.   ls_RFCSYSACL_data-RFCTCDCHK   = snapshot_elem-fieldvalue. " 5
          when 'RFCSNC'.      ls_RFCSYSACL_data-RFCSNC      = snapshot_elem-fieldvalue. " 6
          when 'RFCSLOPT'.    ls_RFCSYSACL_data-RFCSLOPT    = snapshot_elem-fieldvalue. " 7
          " only available in higher versions
          when 'RFCCREDEST'.  ls_RFCSYSACL_data-RFCCREDEST  = snapshot_elem-fieldvalue. " 8
          when 'RFCREGDEST'.  ls_RFCSYSACL_data-RFCREGDEST  = snapshot_elem-fieldvalue. " 9
          when 'LLICENSE_NR'. ls_RFCSYSACL_data-LLICENSE_NR = snapshot_elem-fieldvalue. " 10
          when 'RFCSECKEY'.   ls_RFCSYSACL_data-RFCSECKEY   = snapshot_elem-fieldvalue. " 11
        endcase.
      endloop.

      " Add installation number
      if ls_RFCSYSACL_data-LLICENSE_NR is initial.
        ls_RFCSYSACL_data-LLICENSE_NR = ls_TRUSTED_SYSTEM-LLICENSE_NR.
      endif.

      " Store RRFCSYSACL data
      append ls_RFCSYSACL_data to ls_TRUSTED_SYSTEM-RFCSYSACL_data.

      add 1 to ls_result-TRUSTSY_cnt_all.

      if ls_RFCSYSACL_data-RFCTCDCHK is not initial.
        add 1 to ls_result-TRUSTSY_cnt_TCD.
      endif.

      " Get version
      data version(1).
      version = ls_RFCSYSACL_data-RFCSLOPT. " get first char of the string
      case version.
        when '3'. add 1 to ls_result-TRUSTSY_cnt_3.
        when '2'. add 1 to ls_result-TRUSTSY_cnt_2.
        when ' '. add 1 to ls_result-TRUSTSY_cnt_1.
      endcase.

      " Identify selftrust
      if ls_RFCSYSACL_data-RFCSYSID = ls_RFCSYSACL_data-RFCTRUSTSY.
        if ls_RFCSYSACL_data-LLICENSE_NR is not initial and ls_RFCSYSACL_data-LLICENSE_NR = ls_RFCSYSACL_data-TLICENSE_NR.
          ls_result-EXPLICIT_SELFTRUST = 'Explicit selftrust'.
        else.
          ls_result-EXPLICIT_SELFTRUST = 'explicit selftrust'. " no check for installation number
        endif.
      endif.
    ENDLOOP.

    " Store trusted systems
    append ls_TRUSTED_SYSTEM to lt_TRUSTED_SYSTEMS.

    " Store result
    if tabix > 0.
      MODIFY lt_result from ls_result INDEX tabix.
    else.
      APPEND ls_result TO lt_result.
    endif.

  ENDLOOP. " lt_STORE_DIR

ENDFORM. " get_RFCSYSACL

FORM get_RFCDES.
  check P_DEST = 'X'.

  DATA:
    lt_store_dir_tech    TYPE  tt_diagst_store_dir_tech,
    lt_store_dir         TYPE  tt_diagst_store_dir,
    lt_fieldlist         TYPE  tt_diagst_table_store_fields,
    lt_snapshot          TYPE  tt_diagst_trows,
    rc                   TYPE  i,
    rc_text              TYPE  natxt.

  data: tabix type i.

  CALL FUNCTION 'DIAGST_GET_STORES'
    EXPORTING

      " The �System Filter� parameters allow to get all Stores of a system or technical system.
      " Some combinations of the four parameters are not allowed.
      " The function will return an error code in such a case.
*     SID                   = ' '
*     INSTALL_NUMBER        = ' '
*     LONG_SID              = ' '
*     TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)

      " Store key fields
      group_namespace       = 'ACTIVE'                   "(optional)
      group_landscape_class = 'CL_DIAGLS_ABAP_TECH_SYST' "(optional)
*     GROUP_LANDSCAPE_ID    = ' '
*     GROUP_COMP_ID         = ' '
      group_source          = 'ABAP'                     "(optional)
      group_name            = 'RFC-DESTINATIONS'         "(optional)
      store_category        = 'CONFIG'                   "(optional)
      store_type            = 'TABLE'                    "(optional)
*     STORE_FULLPATH        = ' '
      store_name            = 'RFCDES'

      " Special filters
      store_mainalias       = 'RFC-DESTINATIONS'         "(optional)
      store_subalias        = 'RFCDES'                   "(optional)
*     STORE_TPL_ID          = ' '
*     HAS_ELEMENT_FROM      =                            " date range
*     HAS_ELEMENT_TO        =                            " date range
*     ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*     CASE_INSENSITIVE      = ' '
*     PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*     SEARCH_STRING         =
*     ONLY_RELEVANT         = 'X'
*     PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll

      " Others
*     DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
                                                         " Setting this parameter to �X� will display the result.
*     CALLING_APPL          = ' '

    IMPORTING
*     STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
      store_dir             = lt_store_dir               "(not recommended anymore)
*     STORE_DIR_MI          =                            "(SAP internal usage only)
*     STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*     PARAMETER             =                            "(SAP internal usage only)
      rc                    = rc
      rc_text               = rc_text.

  IF rc IS NOT INITIAL.
    MESSAGE e001(00) WITH rc_text.
  ENDIF.

  LOOP AT lt_store_dir INTO data(ls_store_dir)
    WHERE long_sid              IN p_sid
      AND store_main_state_type IN p_state
    .

    " Do we already have an entry for this system?
    READ table lt_result into ls_result
      with key
        install_number = ls_store_dir-install_number
        long_sid       = ls_store_dir-long_sid
        sid            = ls_store_dir-sid
        .
    if sy-subrc = 0.
      tabix = sy-tabix.
    else.
      tabix = -1.
      CLEAR ls_result.
      MOVE-CORRESPONDING ls_store_dir TO ls_result.
    endif.

    CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
      EXPORTING
        store_id                    = ls_store_dir-store_id
*       TIMESTAMP                   =                        " if not specified the latest available snapshot is returned
*       CALLING_APPL                = ' '
      IMPORTING
        fieldlist                   = lt_fieldlist
*       SNAPSHOT_VALID_FROM         =
*       SNAPSHOT_VALID_TO_CONFIRMED =
*       SNAPSHOT_VALID_TO           =
        snapshot                    = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*       SNAPSHOT_TR                 =
*       SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
        rc                          = rc                     " 3: Permission denied, Content Authorization missing
                                                             " 4: Store not existing
                                                             " 8: Error
        rc_text                     = rc_text.

    LOOP AT lt_snapshot INTO data(lt_snapshot_elem).
      READ TABLE lt_snapshot_elem INTO data(ls_RFCDEST)       INDEX 1.
      check ls_RFCDEST-fieldname = 'RFCDEST'.

      READ TABLE lt_snapshot_elem INTO data(ls_RFCTYPE)       INDEX 2.
      check ls_RFCTYPE-fieldname = 'RFCTYPE'.
      check ls_RFCTYPE-fieldvalue = '3' or  ls_RFCTYPE-fieldvalue = 'H' or ls_RFCTYPE-fieldvalue =  'W'.

      READ TABLE lt_snapshot_elem INTO data(ls_RFCOPTIONS)    INDEX 3.
      check ls_RFCOPTIONS-fieldname = 'RFCOPTIONS'.

      case ls_RFCTYPE-fieldvalue.

        when '3'. " RFC destinations
          P_DEST_3 = 'X'.
          add 1 to ls_result-DEST_3_cnt_all.                             " All destinations

          if ls_RFCOPTIONS-fieldvalue cs ',Q=Y,'.                        " Trusted destination
            add 1 to ls_result-DEST_3_cnt_trusted.

            find regex ',\[=[^,]{3},'    in ls_RFCOPTIONS-fieldvalue.    " System ID
            if sy-subrc = 0.
              find regex ',\^=[^,]{1,10},' in ls_RFCOPTIONS-fieldvalue.  " Installation number
              if sy-subrc = 0.
                " System ID and installation number are available
                add 1 to ls_result-DEST_3_cnt_trusted_migrated.
              else.
                " Installation number is missing
                add 1 to ls_result-DEST_3_cnt_trusted_no_instnr.
              endif.
            else.
              " System ID is missing
              add 1 to ls_result-DEST_3_cnt_trusted_no_sysid.
            endif.

            if ls_RFCOPTIONS-fieldvalue cs ',s=Y,'.                      " SNC
              add 1 to ls_result-DEST_3_cnt_trusted_snc.
            endif.
          endif.

        when 'H'. " http destinations
          P_DEST_H = 'X'.
          add 1 to ls_result-DEST_H_cnt_all.                             " All destinations

          if ls_RFCOPTIONS-fieldvalue cs ',Q=Y,'.                        " Trusted destination
            add 1 to ls_result-DEST_H_cnt_trusted.

            find regex ',\[=[^,]{3},'    in ls_RFCOPTIONS-fieldvalue.    " System ID
            if sy-subrc = 0.
              find regex ',\^=[^,]{1,10},' in ls_RFCOPTIONS-fieldvalue.  " Installation number
              if sy-subrc = 0.
                " System ID and installation number are available
                add 1 to ls_result-DEST_H_cnt_trusted_migrated.
              else.
                " Installation number is missing
                add 1 to ls_result-DEST_H_cnt_trusted_no_instnr.
              endif.
            else.
              " System ID is missing
              add 1 to ls_result-DEST_H_cnt_trusted_no_sysid.
            endif.

            if ls_RFCOPTIONS-fieldvalue cs ',s=Y,'.                      " TLS
              add 1 to ls_result-DEST_H_cnt_trusted_tls.
            endif.
          endif.

        when 'W'. " web RFC destinations
          P_DEST_W = 'X'.
          add 1 to ls_result-DEST_W_cnt_all.                             " All destinations

          if ls_RFCOPTIONS-fieldvalue cs ',Q=Y,'.                        " Trusted destination
            add 1 to ls_result-DEST_W_cnt_trusted.

            find regex ',\[=[^,]{3},'    in ls_RFCOPTIONS-fieldvalue.    " System ID
            if sy-subrc = 0.
              find regex ',\^=[^,]{1,10},' in ls_RFCOPTIONS-fieldvalue.  " Installation number
              if sy-subrc = 0.
                " System ID and installation number are available
                add 1 to ls_result-DEST_W_cnt_trusted_migrated.
              else.
                " Installation number is missing
                add 1 to ls_result-DEST_W_cnt_trusted_no_instnr.
              endif.
            else.
              " System ID is missing
              add 1 to ls_result-DEST_W_cnt_trusted_no_sysid.
            endif.

            if ls_RFCOPTIONS-fieldvalue cs ',s=Y,'.                      " TLS
              add 1 to ls_result-DEST_W_cnt_trusted_tls.
            endif.
          endif.

      endcase.

    ENDLOOP.

    if tabix > 0.
      MODIFY lt_result from ls_result INDEX tabix.
    else.
      APPEND ls_result TO lt_result.
    endif.

  ENDLOOP. " lt_STORE_DIR

ENDFORM. " get_RFCDES

FORM get_ABAP_INSTANCE_PAHI.
  check P_TRUST = 'X' or P_DEST = 'X'.

  " Same as in report ZSHOW_KERNEL_STORES but one one entry per system

  DATA:
    lt_store_dir_tech    TYPE  tt_diagst_store_dir_tech,
    lt_store_dir         TYPE  tt_diagst_store_dir,
    lt_fieldlist         TYPE  tt_diagst_table_store_fields,
    lt_snapshot          TYPE  tt_diagst_trows,
    rc                   TYPE  i,
    rc_text              TYPE  natxt.

  data: tabix type i.

  CALL FUNCTION 'DIAGST_GET_STORES'
    EXPORTING

      " The �System Filter� parameters allow to get all Stores of a system or technical system.
      " Some combinations of the four parameters are not allowed.
      " The function will return an error code in such a case.
*     SID                   = ' '
*     INSTALL_NUMBER        = ' '
*     LONG_SID              = ' '
*     TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)

      " Store key fields
      group_namespace       = 'ACTIVE'                   "(optional)
      group_landscape_class = 'CL_DIAGLS_ABAP_INSTANCE'  "(optional)
*     GROUP_LANDSCAPE_ID    = ' '
*     GROUP_COMP_ID         = ' '
      group_source          = 'ABAP'                     "(optional)
      group_name            = 'INSTANCE'                 "(optional)
      store_category        = 'CONFIG'                   "(optional)
      store_type            = 'PROPERTY'                 "(optional)
*     STORE_FULLPATH        = ' '
      store_name            = 'ABAP_INSTANCE_PAHI'

      " Special filters
      store_mainalias       = 'ABAP-PARAMETER'           "(optional)
      store_subalias        = 'PAHI'                     "(optional)
*     STORE_TPL_ID          = ' '
*     HAS_ELEMENT_FROM      =                            " date range
*     HAS_ELEMENT_TO        =                            " date range
*     ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*     CASE_INSENSITIVE      = ' '
*     PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*     SEARCH_STRING         =
*     ONLY_RELEVANT         = 'X'
*     PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll

      " Others
*     DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
                                                         " Setting this parameter to �X� will display the result.
*     CALLING_APPL          = ' '

    IMPORTING
*     STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
      store_dir             = lt_store_dir               "(not recommended anymore)
*     STORE_DIR_MI          =                            "(SAP internal usage only)
*     STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*     PARAMETER             =                            "(SAP internal usage only)
      rc                    = rc
      rc_text               = rc_text.

  IF rc IS NOT INITIAL.
    MESSAGE e001(00) WITH rc_text.
  ENDIF.

  LOOP AT lt_store_dir INTO data(ls_store_dir)
    WHERE long_sid              IN p_sid
      AND store_main_state_type IN p_state
    .

    " Do we already have an entry for this system?
    READ table lt_result into ls_result
      with key
        install_number = ls_store_dir-install_number
        long_sid       = ls_store_dir-long_sid
        sid            = ls_store_dir-sid
        .
    if sy-subrc = 0.
      tabix = sy-tabix.
      if ls_store_dir-instance_type ne 'CENTRAL'.
        continue.
      endif.
    else.
      tabix = -1.
      CLEAR ls_result.
      MOVE-CORRESPONDING ls_store_dir TO ls_result.
    endif.

    IF ls_result-host_full IS INITIAL.
      ls_result-host_full = ls_result-host. " host, host_id, physical_host
    ENDIF.

    CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
      EXPORTING
        store_id                    = ls_store_dir-store_id
*       TIMESTAMP                   =                        " if not specified the latest available snapshot is returned
*       CALLING_APPL                = ' '
      IMPORTING
        fieldlist                   = lt_fieldlist
*       SNAPSHOT_VALID_FROM         =
*       SNAPSHOT_VALID_TO_CONFIRMED =
*       SNAPSHOT_VALID_TO           =
        snapshot                    = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*       SNAPSHOT_TR                 =
*       SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
        rc                          = rc                     " 3: Permission denied, Content Authorization missing
                                                             " 4: Store not existing
                                                             " 8: Error
        rc_text                     = rc_text.

    LOOP AT lt_snapshot INTO data(lt_snapshot_elem).
      READ TABLE lt_snapshot_elem INTO data(ls_PARAMETER) INDEX 1.
      check ls_PARAMETER-fieldname = 'PARAMETER'.

      READ TABLE lt_snapshot_elem INTO data(ls_VALUE)     INDEX 2.
      check ls_VALUE-fieldname = 'VALUE'.

      case ls_PARAMETER-fieldvalue.
        when 'rfc/selftrust'.         ls_result-rfc_selftrust         = ls_VALUE-fieldvalue.
        when 'rfc/allowoldticket4tt'. ls_result-rfc_allowoldticket4tt = ls_VALUE-fieldvalue.
        when 'rfc/sendInstNr4tt'.     ls_result-rfc_sendInstNr4tt     = ls_VALUE-fieldvalue.
      endcase.
    ENDLOOP.

    if tabix > 0.
      MODIFY lt_result from ls_result INDEX tabix.
    else.
      APPEND ls_result TO lt_result.
    endif.

  ENDLOOP. " lt_STORE_DIR

ENDFORM. " get_ABAP_INSTANCE_PAHI

FORM validate_kernel.
  check P_KERN = 'X'.

* Minimum Kernel
* The solution works only if both the client systems as well as the server systems of a trusting/trusted connection runs on a suitable Kernel version:
* 7.22       1214
* 7.49       Not Supported. Use 753 / 754 instead
* 7.53       (1028) 1036
* 7.54       18
* 7.77       (500) 516
* 7.81       (251) 300
* 7.85       (116, 130)  214
* 7.88       21
* 7.89       10

  data:
    rel   type i,
    patch type i.

  loop at lt_result ASSIGNING FIELD-SYMBOL(<fs_result>).

    if <fs_result>-kern_rel is initial or <fs_result>-kern_patchlevel is INITIAL.
      <fs_result>-validate_kernel = 'Unknown Kernel'.
      APPEND VALUE #( fname = 'VALIDATE_KERNEL' color-col = col_normal ) TO <fs_result>-t_color.

    else.
      rel   = <fs_result>-kern_rel(3).
      patch = ls_result-kern_patchlevel.

      if     rel = 722 and patch < 1214
        or   rel = 753 and patch < 1036
        or   rel = 754 and patch < 18
        or   rel = 777 and patch < 516
        or   rel = 781 and patch < 300
        or   rel = 785 and patch < 214
        or   rel = 788 and patch < 21
        or   rel = 789 and patch < 10
        .
        <fs_result>-validate_kernel = 'Kernel patch required'.
        APPEND VALUE #( fname = 'VALIDATE_KERNEL' color-col = col_total ) TO <fs_result>-t_color.

      elseif rel < 722
          or rel > 722 and rel < 753
          .
        <fs_result>-validate_kernel = `Release update required`.
        APPEND VALUE #( fname = 'VALIDATE_KERNEL' color-col = col_negative ) TO <fs_result>-t_color.

      else.

        <fs_result>-validate_kernel = 'ok'.
        APPEND VALUE #( fname = 'VALIDATE_KERNEL' color-col = col_positive ) TO <fs_result>-t_color.

      endif.
    endif.
  endloop.
ENDFORM. " validate_kernel

FORM validate_ABAP.
  check P_ABAP = 'X' or P_TRUST = 'X' or P_DEST = 'X'.

* Minimum SAP_BASIS for SNOTE
* You only can implement the notes 3089413 and 3287611 using transaction SNOTE if the system runs on a suitable ABAP version:
*                minimum   Note 3089413 solved   Note 3287611 solved
* SAP_BASIS 700  SP 35     SP 41
* SAP_BASIS 701  SP 20     SP 26
* SAP_BASIS 702  SP 20     SP 26
* SAP_BASIS 731  SP 19     SP 33
* SAP_BASIS 740  SP 16     SP 30
* SAP_BASIS 750  SP 12     SP 26                 SP 27
* SAP_BASIS 751  SP 7      SP 16                 SP 17
* SAP_BASIS 752  SP 1      SP 12
* SAP_BASIS 753            SP 10
* SAP_BASIS 754            SP 8
* SAP_BASIS 755            SP 6
* SAP_BASIS 756            SP 4
* SAP_BASIS 757            SP 2

  data:
    rel   type i,
    SP    type i.

  loop at lt_result assigning FIELD-SYMBOL(<fs_result>).

    " Validate release and SP
    if <fs_result>-ABAP_RELEASE is initial or <fs_result>-ABAP_SP is INITIAL.
      <fs_result>-validate_ABAP = 'Unknown ABAP version'.
      APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_normal ) TO <fs_result>-t_color.

    else.
      rel   = <fs_result>-ABAP_RELEASE.
      SP    = <fs_result>-ABAP_SP.

      if     rel < 700
        or   rel = 700 and SP < 35
        or   rel = 701 and SP < 20
        or   rel = 702 and SP < 20
        or   rel = 731 and SP < 19
        or   rel = 740 and SP < 16
        or   rel = 750 and SP < 12
        or   rel = 751 and SP < 7
        or   rel = 752 and SP < 1
        .
        <fs_result>-validate_ABAP = 'ABAP SP required'.
        APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_negative ) TO <fs_result>-t_color.

      elseif rel = 700 and SP < 41
        or   rel = 701 and SP < 26
        or   rel = 702 and SP < 26
        or   rel = 731 and SP < 33
        or   rel = 740 and SP < 30
        or   rel = 750 and SP < 26
        or   rel = 751 and SP < 16
        or   rel = 752 and SP < 12
        or   rel = 753 and SP < 10
        or   rel = 754 and SP < 8
        or   rel = 755 and SP < 6
        or   rel = 756 and SP < 4
        or   rel = 757 and SP < 2
        or   rel > 757
        .
        <fs_result>-validate_ABAP = 'Note required'.
        APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_total ) TO <fs_result>-t_color.

        if <fs_result>-NOTE_3089413 is initial.
           <fs_result>-NOTE_3089413 = 'required'.
        endif.
        if <fs_result>-NOTE_3287611 is initial.
           <fs_result>-NOTE_3287611 = 'required'.
        endif.

      elseif rel = 750 and SP < 27
        or   rel = 751 and SP < 17
        .
        <fs_result>-validate_ABAP = 'Note required'.
        APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_total ) TO <fs_result>-t_color.

        if <fs_result>-NOTE_3089413 is initial.
           <fs_result>-NOTE_3089413 = 'ok'.
        endif.
        if <fs_result>-NOTE_3287611 is initial.
           <fs_result>-NOTE_3287611 = 'required'.
        endif.

      else.
        <fs_result>-validate_ABAP = 'ok'.
        APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_positive ) TO <fs_result>-t_color.

        if <fs_result>-NOTE_3089413 is initial.
           <fs_result>-NOTE_3089413 = 'ok'.
        endif.
        if <fs_result>-NOTE_3287611 is initial.
           <fs_result>-NOTE_3287611 = 'ok'.
        endif.

      endif.
    endif.

    " Validate notes
    "   Undefined Implementation State
    " -	Cannot be implemented
    " E	Completely implemented
    " N	Can be implemented
    " O	Obsolete
    " U	Incompletely implemented
    " V	Obsolete version implemented
    case <fs_result>-NOTE_3089413_PRSTATUS.
      when 'E' or '-'.
        APPEND VALUE #( fname = 'NOTE_3089413' color-col = col_positive ) TO <fs_result>-t_color.
      when 'N' or 'O' or 'U' or 'V'.
        APPEND VALUE #( fname = 'NOTE_3089413' color-col = col_negative ) TO <fs_result>-t_color.
      when others.
        if     <fs_result>-NOTE_3089413 = 'ok'.
          APPEND VALUE #( fname = 'NOTE_3089413' color-col = col_positive ) TO <fs_result>-t_color.
        elseif <fs_result>-NOTE_3089413 = 'required'.
          APPEND VALUE #( fname = 'NOTE_3089413' color-col = col_negative ) TO <fs_result>-t_color.
        endif.
    endcase.
    case <fs_result>-NOTE_3287611_PRSTATUS.
      when 'E' or '-'.
        APPEND VALUE #( fname = 'NOTE_3287611' color-col = col_positive ) TO <fs_result>-t_color.
      when 'N' or 'O' or 'U' or 'V'.
        APPEND VALUE #( fname = 'NOTE_3287611' color-col = col_negative ) TO <fs_result>-t_color.
      when others.
        if     <fs_result>-NOTE_3287611 = 'ok'.
          APPEND VALUE #( fname = 'NOTE_3287611' color-col = col_positive ) TO <fs_result>-t_color.
        elseif <fs_result>-NOTE_3287611 = 'required'.
          APPEND VALUE #( fname = 'NOTE_3287611' color-col = col_negative ) TO <fs_result>-t_color.
        endif.
    endcase.

    " Validate trusted systems
    if <fs_result>-TRUSTSY_cnt_3 > 0.
      APPEND VALUE #( fname = 'TRUSTSY_CNT_3' color-col = col_positive ) TO <fs_result>-t_color.
    endif.
    if <fs_result>-TRUSTSY_cnt_2 > 0.
      APPEND VALUE #( fname = 'TRUSTSY_CNT_2' color-col = col_negative ) TO <fs_result>-t_color.
    endif.
    if <fs_result>-TRUSTSY_cnt_1 > 0.
      APPEND VALUE #( fname = 'TRUSTSY_CNT_1' color-col = col_negative ) TO <fs_result>-t_color.
    endif.

    " Validate TCD flag
    if <fs_result>-TRUSTSY_CNT_TCD > 0.
      APPEND VALUE #( fname = 'TRUSTSY_CNT_TCD' color-col = col_positive ) TO <fs_result>-t_color.
    endif.

    " Validate rfc/selftrust
    if <fs_result>-rfc_selftrust = '0'.
      APPEND VALUE #( fname = 'RFC_SELFTRUST' color-col = col_positive ) TO <fs_result>-t_color.
    elseif <fs_result>-rfc_selftrust = '1'.
      APPEND VALUE #( fname = 'RFC_SELFTRUST' color-col = col_total ) TO <fs_result>-t_color.
    endif.

    " Validate trusted destinations
    if <fs_result>-DEST_3_CNT_TRUSTED_MIGRATED > 0.
      APPEND VALUE #( fname = 'DEST_3_CNT_TRUSTED_MIGRATED' color-col = col_positive ) TO <fs_result>-t_color.
    endif.
    if <fs_result>-DEST_3_CNT_TRUSTED_NO_INSTNR > 0.
      APPEND VALUE #( fname = 'DEST_3_CNT_TRUSTED_NO_INSTNR' color-col = col_negative ) TO <fs_result>-t_color.
    endif.
    if <fs_result>-DEST_3_CNT_TRUSTED_NO_SYSID > 0.
      APPEND VALUE #( fname = 'DEST_3_CNT_TRUSTED_NO_SYSID' color-col = col_negative ) TO <fs_result>-t_color.
    endif.

    if <fs_result>-DEST_H_CNT_TRUSTED_MIGRATED > 0.
      APPEND VALUE #( fname = 'DEST_H_CNT_TRUSTED_MIGRATED' color-col = col_positive ) TO <fs_result>-t_color.
    endif.
    if <fs_result>-DEST_H_CNT_TRUSTED_NO_INSTNR > 0.
      APPEND VALUE #( fname = 'DEST_H_CNT_TRUSTED_NO_INSTNR' color-col = col_negative ) TO <fs_result>-t_color.
    endif.
    if <fs_result>-DEST_H_CNT_TRUSTED_NO_SYSID > 0.
      APPEND VALUE #( fname = 'DEST_H_CNT_TRUSTED_NO_SYSID' color-col = col_negative ) TO <fs_result>-t_color.
    endif.

    if <fs_result>-DEST_W_CNT_TRUSTED_MIGRATED > 0.
      APPEND VALUE #( fname = 'DEST_W_CNT_TRUSTED_MIGRATED' color-col = col_positive ) TO <fs_result>-t_color.
    endif.
    if <fs_result>-DEST_W_CNT_TRUSTED_NO_INSTNR > 0.
      APPEND VALUE #( fname = 'DEST_W_CNT_TRUSTED_NO_INSTNR' color-col = col_negative ) TO <fs_result>-t_color.
    endif.
    if <fs_result>-DEST_W_CNT_TRUSTED_NO_SYSID > 0.
      APPEND VALUE #( fname = 'DEST_3_CNT_TRUSTED_NO_SYSID' color-col = col_negative ) TO <fs_result>-t_color.
    endif.

  endloop.
ENDFORM. " validate_ABAP

FORM validate_mutual_trust.
  check P_TRUST = 'X'.

  FIELD-SYMBOLS:
    <fs_TRUSTED_SYSTEM>   type ts_TRUSTED_SYSTEM,
    <fs_RFCSYSACL_data>   type ts_RFCSYSACL_data,
    <fs_TRUSTED_SYSTEM_2> type ts_TRUSTED_SYSTEM,
    <fs_RFCSYSACL_data_2> type ts_RFCSYSACL_data,
    <fs_result>           type ts_result.

*  " Fast but only possible if LLICENSE_NR is available
*  " For all trusting systems
*  loop at lt_TRUSTED_SYSTEMS ASSIGNING <fs_TRUSTED_SYSTEM>.
*
*    " Get trusted systems
*    loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data ASSIGNING <fs_RFCSYSACL_data>
*      where RFCSYSID    ne <fs_TRUSTED_SYSTEM>-RFCTRUSTSY   " Ignore selftrust
*         "or TLICENSE_NR ne <fs_TRUSTED_SYSTEM>-LLICENSE_NR
*         .
*
*      " Get data of these trusted systems
*      read table lt_TRUSTED_SYSTEMS ASSIGNING <fs_TRUSTED_SYSTEM_2>
*        WITH TABLE KEY
*          RFCTRUSTSY  = <fs_RFCSYSACL_data>-RFCSYSID
*          LLICENSE_NR = <fs_RFCSYSACL_data>-TLICENSE_NR
*          .
*      if sy-subrc = 0.
*
*        " Check for mutual trust
*        read table <fs_TRUSTED_SYSTEM_2>-RFCSYSACL_data ASSIGNING <fs_RFCSYSACL_data_2>
*          WITH TABLE KEY
*            RFCSYSID     = <fs_RFCSYSACL_data>-RFCTRUSTSY
*            TLICENSE_NR  = <fs_RFCSYSACL_data>-LLICENSE_NR
*            .
*        if sy-subrc = 0
*          "and <fs_RFCSYSACL_data>-RFCSYSID       = <fs_RFCSYSACL_data_2>-RFCTRUSTSY
*          "and <fs_RFCSYSACL_data>-TLICENSE_NR    = <fs_RFCSYSACL_data_2>-LLICENSE_NR
*          "and <fs_RFCSYSACL_data_2>-RFCSYSID     = <fs_RFCSYSACL_data>-RFCTRUSTSY
*          "and <fs_RFCSYSACL_data_2>-TLICENSE_NR  = <fs_RFCSYSACL_data>-LLICENSE_NR
*          .
*          " Store mutual trust
*          "...
*        endif.
*
*      endif.
*
*    endloop.
*  endloop.

  " Slow, and maybe inaccurate ignoring LLICENSE_NR
  " For all trusting systems
  loop at lt_TRUSTED_SYSTEMS ASSIGNING <fs_TRUSTED_SYSTEM>.

    " Get trusted systems
    loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data ASSIGNING <fs_RFCSYSACL_data>
      where RFCSYSID    ne <fs_TRUSTED_SYSTEM>-RFCTRUSTSY   " Ignore selftrust
         "or TLICENSE_NR ne <fs_TRUSTED_SYSTEM>-LLICENSE_NR
         .

      loop at lt_TRUSTED_SYSTEMS ASSIGNING <fs_TRUSTED_SYSTEM_2>
        where RFCTRUSTSY  = <fs_RFCSYSACL_data>-RFCSYSID
          "and LLICENSE_NR = <fs_RFCSYSACL_data>-TLICENSE_NR
          .

        loop at <fs_TRUSTED_SYSTEM_2>-RFCSYSACL_data ASSIGNING <fs_RFCSYSACL_data_2>
          WHERE RFCSYSID     = <fs_RFCSYSACL_data>-RFCTRUSTSY
            "and TLICENSE_NR  = <fs_RFCSYSACL_data>-LLICENSE_NR
            .

          " Store mutual trust
          read table lt_result ASSIGNING <fs_result>
            with key
              install_number = <fs_RFCSYSACL_data>-LLICENSE_NR
              "long_sid       =
              sid            = <fs_RFCSYSACL_data>-RFCTRUSTSY
              .
          if sy-subrc = 0.
            add 1 to <fs_result>-MUTUAL_TRUST_CNT.
            if <fs_result>-MUTUAL_TRUST_CNT = 1.
              APPEND VALUE #( fname = 'MUTUAL_TRUST_CNT' color-col = col_total ) TO <fs_result>-t_color.
            endif.
          endif.

          <fs_RFCSYSACL_data>-MUTUAL_TRUST   = 'mutual'.
          <fs_RFCSYSACL_data_2>-MUTUAL_TRUST = 'mutual'.

          "write: /(3) <fs_RFCSYSACL_data>-RFCSYSID,     <fs_RFCSYSACL_data>-TLICENSE_NR,   (3) <fs_RFCSYSACL_data>-RFCTRUSTSY,   <fs_RFCSYSACL_data>-LLICENSE_NR.   " <fs_RFCSYSACL_data>
          "write:  (3) <fs_RFCSYSACL_data_2>-RFCTRUSTSY, <fs_RFCSYSACL_data_2>-LLICENSE_NR, (3) <fs_RFCSYSACL_data_2>-RFCSYSID,   <fs_RFCSYSACL_data_2>-TLICENSE_NR. " <fs_RFCSYSACL_data_2>

        endloop.
      endloop.

      if sy-subrc is not initial                      " No data of trusted system found?
        and <fs_RFCSYSACL_data>-RFCSYSID in p_sid.    " But check this only of data should be available

        " Store mutual trust
        read table lt_result ASSIGNING <fs_result>
          with key
            install_number = <fs_RFCSYSACL_data>-LLICENSE_NR
            "long_sid       =
            sid            = <fs_RFCSYSACL_data>-RFCTRUSTSY
            .
        if sy-subrc = 0.
          add 1 to <fs_result>-NO_DATA_CNT.
          if <fs_result>-MUTUAL_TRUST_CNT = 1.
            APPEND VALUE #( fname = 'MUTUAL_TRUST_CNT' color-col = col_total ) TO <fs_result>-t_color.
          endif.
        endif.

        <fs_RFCSYSACL_data>-NO_DATA = 'no data'.

      endif.
    endloop.
  endloop.

endform.

*---------------------------------------------------------------------*
*      CLASS lcl_handle_events DEFINITION
*---------------------------------------------------------------------*
* define a local class for handling events of cl_salv_table
*---------------------------------------------------------------------*
CLASS lcl_handle_events DEFINITION.

  PUBLIC SECTION.

    METHODS:
      on_user_command FOR EVENT added_function OF cl_salv_events
        IMPORTING e_salv_function,

      on_double_click FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column.

*      on_single_click for event link_click of cl_salv_events_table
*        importing row column.

  PRIVATE SECTION.
    DATA: dialogbox_status TYPE c.  "'X': does exist, SPACE: does not ex.

ENDCLASS.                    "lcl_handle_events DEFINITION

* main data table
DATA: gr_alv_table      TYPE REF TO cl_salv_table.

* for handling the events of cl_salv_table
DATA: gr_alv_events     TYPE REF TO lcl_handle_events.

*----------------------------------------------------------------------*
*      CLASS lcl_handle_events IMPLEMENTATION
*----------------------------------------------------------------------*
* implement the events for handling the events of cl_salv_table
*----------------------------------------------------------------------*
CLASS lcl_handle_events IMPLEMENTATION.

  METHOD on_user_command.
*    importing e_salv_function

    " Get selected item(s)
    data(lr_selections)   = gr_alv_table->get_selections( ).
    data(ls_cell)         = lr_selections->get_current_cell( ).
    data(lt_seleced_rows) = lr_selections->get_selected_rows( ).

    CASE e_salv_function.

      WHEN 'PICK'. " Double click

        " Show trusted systems
        if   ls_cell-columnname(12) = 'TRUSTSY_CNT_'
          or ls_cell-columnname = 'MUTUAL_TRUST_CNT'
          or ls_cell-columnname = 'NO_DATA_CNT'.

          IF ls_cell-row > 0.

            READ TABLE lt_result INTO data(ls_result) INDEX ls_cell-row.
            check sy-subrc = 0.

            perform show_trusted_systems
              using
                ls_cell-columnname
                ls_result-install_number " LLICENSE_NR
                ls_result-sid            " RFCTRUSTSY
                .

          ENDIF.
        endif.
    ENDCASE.

  ENDMETHOD.                    "on_user_command

  METHOD on_double_click.
*   importing row column

    " Get selected item(s)
    data(lr_selections) = gr_ALV_TABLE->get_selections( ).
    data(ls_cell) = lr_selections->get_current_cell( ).
    data(lt_seleced_rows) = lr_selections->get_selected_rows( ).

    " Show trusted systems
    if   column(12) = 'TRUSTSY_CNT_'
      or column = 'MUTUAL_TRUST_CNT'
      or column = 'NO_DATA_CNT'.

      if row > 0.

        READ TABLE lt_result INTO data(ls_result) INDEX row.
        check sy-subrc = 0.

        perform show_trusted_systems
          using
            column
            ls_result-install_number " LLICENSE_NR
            ls_result-sid            " RFCTRUSTSY
            .

      endif.
    endif.

  ENDMETHOD.                    "on_double_click

ENDCLASS.                    "lcl_handle_events IMPLEMENTATION

FORM show_result.
  DATA:
    lr_functions  TYPE REF TO cl_salv_functions_list,      " Generic and Application-Specific Functions
    lr_display    TYPE REF TO cl_salv_display_settings,    " Appearance of the ALV Output
    lr_functional TYPE REF TO cl_salv_functional_settings,
    lr_sorts      TYPE REF TO cl_salv_sorts,        " All Sort Objects
    "lr_aggregations      type ref to cl_salv_aggregations,
    "lr_filters           type ref to cl_salv_filters,
    "lr_print             type ref to cl_salv_print,
    lr_selections TYPE REF TO cl_salv_selections,
    lr_events     TYPE REF TO cl_salv_events_table,
    "lr_hyperlinks TYPE REF TO cl_salv_hyperlinks,
    "lr_tooltips   TYPE REF TO cl_salv_tooltips,
    "lr_grid_header TYPE REF TO cl_salv_form_layout_grid,
    "lr_grid_footer TYPE REF TO cl_salv_form_layout_grid,
    lr_columns    TYPE REF TO cl_salv_columns_table,       " All Column Objects
    lr_column     TYPE REF TO cl_salv_column_table,        " Columns in Simple, Two-Dimensional Tables
    lr_layout     TYPE REF TO cl_salv_layout,               " Settings for Layout
    ls_layout_key TYPE salv_s_layout_key.

  "data:
  "  header              type lvc_title,
  "  header_size         type salv_de_header_size,
  "  f2code              type syucomm,
  "  buffer              type salv_de_buffer,

  TRY.
      cl_salv_table=>factory(
          EXPORTING
            list_display = abap_false "  false: grid, true: list
        IMPORTING
          r_salv_table = gr_alv_table
        CHANGING
          t_table      = lt_result ).
    CATCH cx_salv_msg.
  ENDTRY.

*... activate ALV generic Functions
  lr_functions = gr_alv_table->get_functions( ).
  lr_functions->set_all( abap_true ).

*... set the display settings
  lr_display = gr_alv_table->get_display_settings( ).
  TRY.
      lr_display->set_list_header( sy-title ).
      "lr_display->set_list_header( header ).
      "lr_display->set_list_header_size( header_size ).
      lr_display->set_striped_pattern( abap_true ).
      lr_display->set_horizontal_lines( abap_true ).
      lr_display->set_vertical_lines( abap_true ).
      lr_display->set_suppress_empty_data( abap_true ).
    CATCH cx_salv_method_not_supported.
  ENDTRY.

*... set the functional settings
  lr_functional = gr_alv_table->get_functional_settings( ).
  TRY.
      lr_functional->set_sort_on_header_click( abap_true ).
      "lr_functional->set_f2_code( f2code ).
      "lr_functional->set_buffer( gs_test-settings-functional-buffer ).
    CATCH cx_salv_method_not_supported.
  ENDTRY.

* ...Set the layout
  lr_layout = gr_alv_table->get_layout( ).
  ls_layout_key-report = sy-repid.
  lr_layout->set_key( ls_layout_key ).
  lr_layout->set_initial_layout( P_LAYOUT ).
  authority-check object 'S_ALV_LAYO'
                      id 'ACTVT' field '23'.
  if sy-subrc = 0.
    lr_layout->set_save_restriction( cl_salv_layout=>restrict_none ) . "no restictions
  else.
    lr_layout->set_save_restriction( cl_salv_layout=>restrict_user_dependant ) . "user dependend
  endif.

*... sort
  TRY.
      lr_sorts = gr_alv_table->get_sorts( ).
      lr_sorts->add_sort( 'INSTALL_NUMBER' ).
      lr_sorts->add_sort( 'LONG_SID' ).
      lr_sorts->add_sort( 'SID' ).

    CATCH cx_salv_data_error cx_salv_existing cx_salv_not_found.
  ENDTRY.

*... set column appearance
  lr_columns = gr_alv_table->get_columns( ).
  lr_columns->set_optimize( abap_true ). " Optimize column width

*... set the color of cells
  TRY.
      lr_columns->set_color_column( 'T_COLOR' ).
    CATCH cx_salv_data_error.                           "#EC NO_HANDLER
  ENDTRY.

* register to the events of cl_salv_table
  lr_events = gr_alv_table->get_event( ).
  CREATE OBJECT gr_alv_events.
* register to the event USER_COMMAND
  SET HANDLER gr_alv_events->on_user_command FOR lr_events.
* register to the event DOUBLE_CLICK
  SET HANDLER gr_alv_events->on_double_click FOR lr_events.

* set selection mode
  lr_selections = gr_alv_table->get_selections( ).
  lr_selections->set_selection_mode(
  if_salv_c_selection_mode=>row_column ).

  TRY.
*... convert time stamps
      lr_column ?= lr_columns->get_column( 'STORE_LAST_UPLOAD' ).
      lr_column->set_edit_mask( '==TSTMP' ).

*... adjust headings
      DATA color TYPE lvc_s_colo.

      lr_column ?= lr_columns->get_column( 'TECH_SYSTEM_ID' ).
      lr_column->set_long_text( 'Technical system ID' ).
      lr_column->set_medium_text( 'Technical system ID' ).
      lr_column->set_short_text( 'Tech. sys.' ).

      lr_column ?= lr_columns->get_column( 'LANDSCAPE_ID' ).
      lr_column->set_long_text( 'Landscape ID' ).
      lr_column->set_medium_text( 'Landscape ID' ).
      lr_column->set_short_text( 'Landscape' ).

      lr_column ?= lr_columns->get_column( 'HOST_ID' ).
      lr_column->set_long_text( 'Host ID' ).
      lr_column->set_medium_text( 'Host ID' ).
      lr_column->set_short_text( 'Host ID' ).

      lr_column ?= lr_columns->get_column( 'COMPV_NAME' ).
      lr_column->set_long_text( 'ABAP release' ).   "max. 40 characters
      lr_column->set_medium_text( 'ABAP release' ). "max. 20 characters
      lr_column->set_short_text( 'ABAP rel.' ).     "max. 10 characters

      " Kernel

      lr_column ?= lr_columns->get_column( 'KERN_REL' ).
      lr_column->set_long_text( 'Kernel release' ).
      lr_column->set_medium_text( 'Kernel release' ).
      lr_column->set_short_text( 'Kernel rel' ).

      lr_column ?= lr_columns->get_column( 'KERN_PATCHLEVEL' ).
      lr_column->set_long_text( 'Kernel patch level' ).
      lr_column->set_medium_text( 'Kernel patch' ).
      lr_column->set_short_text( 'patch' ).

      lr_column ?= lr_columns->get_column( 'KERN_COMP_TIME' ).
      lr_column->set_long_text( 'Kernel compilation time' ).
      lr_column->set_medium_text( 'Kernel compilation' ).
      lr_column->set_short_text( 'Comp.time' ).

      lr_column ?= lr_columns->get_column( 'KERN_COMP_DATE' ).
      lr_column->set_long_text( 'Kernel compilation date' ).
      lr_column->set_medium_text( 'Kernel compilation' ).
      lr_column->set_short_text( 'Comp.date' ).

      lr_column ?= lr_columns->get_column( 'VALIDATE_KERNEL' ).
      lr_column->set_long_text( 'Validate Kernel' ).
      lr_column->set_medium_text( 'Validate Kernel' ).
      lr_column->set_short_text( 'Kernel?' ).

      " ABAP

      lr_column ?= lr_columns->get_column( 'ABAP_RELEASE' ).
      lr_column->set_long_text( 'ABAP release' ).
      lr_column->set_medium_text( 'ABAP release' ).
      lr_column->set_short_text( 'ABAP rel.' ).

      lr_column ?= lr_columns->get_column( 'ABAP_SP' ).
      lr_column->set_long_text( 'ABAP Support Package' ).
      lr_column->set_medium_text( 'ABAP Support Package' ).
      lr_column->set_short_text( 'ABAP SP' ).

      lr_column ?= lr_columns->get_column( 'VALIDATE_ABAP' ).
      lr_column->set_long_text( 'Validate ABAP' ).
      lr_column->set_medium_text( 'Validate ABAP' ).
      lr_column->set_short_text( 'ABAP?' ).

      " Notes

      lr_column ?= lr_columns->get_column( 'NOTE_3089413' ).
      lr_column->set_long_text( 'Note 3089413' ).
      lr_column->set_medium_text( 'Note 3089413' ).
      lr_column->set_short_text( 'N. 3089413' ).

      lr_column ?= lr_columns->get_column( 'NOTE_3089413_PRSTATUS' ).
      lr_column->set_long_text( 'Note 3089413' ).
      lr_column->set_medium_text( 'Note 3089413' ).
      lr_column->set_short_text( 'N. 3089413' ).

      lr_column ?= lr_columns->get_column( 'NOTE_3287611' ).
      lr_column->set_long_text( 'Note 3287611' ).
      lr_column->set_medium_text( 'Note 3287611' ).
      lr_column->set_short_text( 'N. 3287611' ).

      lr_column ?= lr_columns->get_column( 'NOTE_3287611_PRSTATUS' ).
      lr_column->set_long_text( 'Note 3287611' ).
      lr_column->set_medium_text( 'Note 3287611' ).
      lr_column->set_short_text( 'N. 3287611' ).

      " Trusted systems

      lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_ALL' ).
      lr_column->set_long_text( 'All trusted systems' ).
      lr_column->set_medium_text( 'All trusted systems' ).
      lr_column->set_short_text( 'Trusted' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'NO_DATA_CNT' ).
      lr_column->set_long_text( 'No data of trusted system found' ).
      lr_column->set_medium_text( 'No data found' ).
      lr_column->set_short_text( 'No data' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'MUTUAL_TRUST_CNT' ).
      lr_column->set_long_text( 'Mutual trust relations' ).
      lr_column->set_medium_text( 'Mutual trust' ).
      lr_column->set_short_text( 'Mutual' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_TCD' ).
      lr_column->set_long_text( 'Tcode active for trusted systems' ).
      lr_column->set_medium_text( 'Tcode active' ).
      lr_column->set_short_text( 'TCD active' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_3' ).
      lr_column->set_long_text( 'Migrated trusted systems' ).
      lr_column->set_medium_text( 'Migrated systems' ).
      lr_column->set_short_text( 'Migrated' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_2' ).
      lr_column->set_long_text( 'Old trusted systems' ).
      lr_column->set_medium_text( 'Old trusted systems' ).
      lr_column->set_short_text( 'Old' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_1' ).
      lr_column->set_long_text( 'Very old trusted systems' ).
      lr_column->set_medium_text( 'Very old trusted sys' ).
      lr_column->set_short_text( 'Very old' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'EXPLICIT_SELFTRUST' ).
      lr_column->set_long_text( 'Explicit selftrust defined in SMT1' ).
      lr_column->set_medium_text( 'Explicit selftrust' ).
      lr_column->set_short_text( 'Explicit' ).

      " Profile parameter

      lr_column ?= lr_columns->get_column( 'RFC_ALLOWOLDTICKET4TT' ).
      lr_column->set_long_text( 'Allow old ticket' ).
      lr_column->set_medium_text( 'Allow old ticket' ).
      lr_column->set_short_text( 'Allow old' ).

      lr_column ?= lr_columns->get_column( 'RFC_SELFTRUST' ).
      lr_column->set_long_text( 'RFC selftrust by profile parameter' ).
      lr_column->set_medium_text( 'RFC selftrust by par' ).
      lr_column->set_short_text( 'Selftrust' ).

      lr_column ?= lr_columns->get_column( 'RFC_SENDINSTNR4TT' ).
      lr_column->set_long_text( 'Send installation number' ).
      lr_column->set_medium_text( 'Send installation nr' ).
      lr_column->set_short_text( 'SendInstNr' ).

      " Type 3 Destinations
      color-col = 2. " 2=light blue, 3=yellow, 4=blue, 5=green, 6=red, 7=orange

      lr_column ?= lr_columns->get_column( 'DEST_3_CNT_ALL' ).
      lr_column->set_long_text( 'RFC Destinations (Type 3)' ).
      lr_column->set_medium_text( 'RFC Destinations' ).
      lr_column->set_short_text( 'RFC Dest.' ).
      lr_column->set_zero( abap_false  ).
      lr_column->set_color( color ).

      lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED'  ).
      lr_column->set_long_text( 'Trusted RFC Destinations' ).
      lr_column->set_medium_text( 'Trusted RFC Dest.' ).
      lr_column->set_short_text( 'Trust.RFC' ).
      lr_column->set_zero( abap_false  ).
      lr_column->set_color( color ).

      lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_MIGRATED' ).
      lr_column->set_long_text( 'Migrated Trusted RFC Destinations' ).
      lr_column->set_medium_text( 'Migrated Trusted' ).
      lr_column->set_short_text( 'Migrated' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_NO_INSTNR' ).
      lr_column->set_long_text( 'No Installation Number in Trusted Dest.' ).
      lr_column->set_medium_text( 'No Installation Nr' ).
      lr_column->set_short_text( 'No Inst Nr' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_NO_SYSID' ).
      lr_column->set_long_text( 'No System ID in Trusted RFC Destinations' ).
      lr_column->set_medium_text( 'No System ID' ).
      lr_column->set_short_text( 'No Sys. ID' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_SNC' ).
      lr_column->set_long_text( 'SNC for Trusted RFC Destinations' ).
      lr_column->set_medium_text( 'SNC Trusted Dest' ).
      lr_column->set_short_text( 'SNC Trust.' ).
      lr_column->set_zero( abap_false  ).

      " Type H Destinations

      lr_column ?= lr_columns->get_column( 'DEST_H_CNT_ALL' ).
      lr_column->set_long_text( 'HTTP Destinations (Type H)' ).
      lr_column->set_medium_text( 'HTTP Destinations' ).
      lr_column->set_short_text( 'HTTP Dest.' ).
      lr_column->set_zero( abap_false  ).
      lr_column->set_color( color ).

      lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED'  ).
      lr_column->set_long_text( 'Trusted HTTP Destinations' ).
      lr_column->set_medium_text( 'Trusted HTTPS Dest.' ).
      lr_column->set_short_text( 'Trust.HTTP' ).
      lr_column->set_zero( abap_false  ).
      lr_column->set_color( color ).

      lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_MIGRATED' ).
      lr_column->set_long_text( 'Migrated Trusted HTTP Destinations' ).
      lr_column->set_medium_text( 'Migrated Trusted' ).
      lr_column->set_short_text( 'Migrated' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_NO_INSTNR' ).
      lr_column->set_long_text( 'No Installation Number in Trusted Dest.' ).
      lr_column->set_medium_text( 'No Installation Nr' ).
      lr_column->set_short_text( 'No Inst Nr' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_NO_SYSID' ).
      lr_column->set_long_text( 'No System ID in Trusted HTTP Dest.' ).
      lr_column->set_medium_text( 'No System ID' ).
      lr_column->set_short_text( 'No Sys. ID' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_TLS' ).
      lr_column->set_long_text( 'TLS for Trusted HTTP Destinations' ).
      lr_column->set_medium_text( 'TLS Trusted Dest.' ).
      lr_column->set_short_text( 'TLS Trust.' ).
      lr_column->set_zero( abap_false  ).

      " Type W Destinations

      lr_column ?= lr_columns->get_column( 'DEST_W_CNT_ALL' ).
      lr_column->set_long_text( 'WebRFC Destinations (Type W)' ).
      lr_column->set_medium_text( 'WebRFC Destinations' ).
      lr_column->set_short_text( 'Web Dest.' ).
      lr_column->set_zero( abap_false  ).
      lr_column->set_color( color ).

      lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED'  ).
      lr_column->set_long_text( 'Trusted WebRFC Destinations' ).
      lr_column->set_medium_text( 'Trusted WebRFC Dest.' ).
      lr_column->set_short_text( 'Trust Web' ).
      lr_column->set_zero( abap_false  ).
      lr_column->set_color( color ).

      lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_MIGRATED' ).
      lr_column->set_long_text( 'Migrated Trusted WebRFC Destinations' ).
      lr_column->set_medium_text( 'Migrated Trusted' ).
      lr_column->set_short_text( 'Migrated' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_NO_INSTNR' ).
      lr_column->set_long_text( 'No Installation Number in Trusted Dest.' ).
      lr_column->set_medium_text( 'No Installation Nr' ).
      lr_column->set_short_text( 'No Inst Nr' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_NO_SYSID' ).
      lr_column->set_long_text( 'No System ID in Trusted WebRFC Dest.' ).
      lr_column->set_medium_text( 'No System ID' ).
      lr_column->set_short_text( 'No Sys. ID' ).
      lr_column->set_zero( abap_false  ).

      lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_TLS' ).
      lr_column->set_long_text( 'TLS for Trusted WebRFC Destinations' ).
      lr_column->set_medium_text( 'TLS Trusted Dest.' ).
      lr_column->set_short_text( 'TLS Trust.' ).
      lr_column->set_zero( abap_false  ).


*... hide unimportant columns
      lr_column ?= lr_columns->get_column( 'LONG_SID' ).                lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'SID' ).                     lr_column->set_visible( abap_true ).

      lr_column ?= lr_columns->get_column( 'TECH_SYSTEM_TYPE' ).        lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'TECH_SYSTEM_ID' ).          lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'LANDSCAPE_ID' ).            lr_column->set_visible( abap_false ).

      lr_column ?= lr_columns->get_column( 'HOST_FULL' ).               lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'HOST' ).                    lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'HOST_ID' ).                 lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'PHYSICAL_HOST' ).           lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'INSTANCE_TYPE' ).           lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'INSTANCE' ).                lr_column->set_visible( abap_false ).

      lr_column ?= lr_columns->get_column( 'COMPV_NAME' ).              lr_column->set_visible( abap_false ).

      lr_column ?= lr_columns->get_column( 'KERN_COMP_TIME' ).          lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'KERN_COMP_DATE' ).          lr_column->set_visible( abap_true ).

      lr_column ?= lr_columns->get_column( 'NOTE_3089413_PRSTATUS' ).   lr_column->set_technical( abap_true ).
      lr_column ?= lr_columns->get_column( 'NOTE_3287611_PRSTATUS' ).   lr_column->set_technical( abap_true ).

      lr_column ?= lr_columns->get_column( 'STORE_ID' ).                lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'STORE_LAST_UPLOAD' ).       lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'STORE_STATE' ).             lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'STORE_MAIN_STATE_TYPE' ).   lr_column->set_visible( abap_false ).
      lr_column ?= lr_columns->get_column( 'STORE_MAIN_STATE' ).        lr_column->set_visible( abap_true ).
      lr_column ?= lr_columns->get_column( 'STORE_OUTDATED_DAY' ).      lr_column->set_visible( abap_false ).

      if P_KERN is initial.
        lr_column ?= lr_columns->get_column( 'KERN_REL' ).              lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'KERN_PATCHLEVEL' ).       lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'KERN_COMP_TIME' ).        lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'KERN_COMP_DATE' ).        lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'VALIDATE_KERNEL' ).       lr_column->set_technical( abap_true ).
      endif.

      if P_ABAP is initial.
        lr_column ?= lr_columns->get_column( 'ABAP_RELEASE' ).          lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'ABAP_SP' ).               lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'VALIDATE_ABAP' ).         lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'NOTE_3089413' ).          lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'NOTE_3089413_PRSTATUS' ). lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'NOTE_3287611' ).          lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'NOTE_3287611_PRSTATUS' ). lr_column->set_technical( abap_true ).
      endif.

      if P_TRUST is initial.
        lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_ALL' ).       lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'NO_DATA_CNT' ).           lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'MUTUAL_TRUST_CNT' ).      lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_TCD' ).       lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_3' ).         lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_2' ).         lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'TRUSTSY_CNT_1' ).         lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'EXPLICIT_SELFTRUST' ).    lr_column->set_technical( abap_true ).

        lr_column ?= lr_columns->get_column( 'RFC_SELFTRUST' ).         lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'RFC_SENDINSTNR4TT' ).     lr_column->set_technical( abap_true ).
      endif.

      if P_DEST is initial or P_DEST_3 is initial.
        lr_column ?= lr_columns->get_column( 'DEST_3_CNT_ALL' ).               lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED' ).           lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_MIGRATED' ).  lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_NO_INSTNR' ). lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_NO_SYSID' ).  lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_SNC' ).       lr_column->set_technical( abap_true ).
      endif.

      if P_DEST is initial or P_DEST_H is initial.
        lr_column ?= lr_columns->get_column( 'DEST_H_CNT_ALL' ).               lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED' ).           lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_MIGRATED' ).  lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_NO_INSTNR' ). lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_NO_SYSID' ).  lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_TLS' ).       lr_column->set_technical( abap_true ).
      endif.

      if P_DEST is initial or P_DEST_W is initial.
        lr_column ?= lr_columns->get_column( 'DEST_W_CNT_ALL' ).               lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED' ).           lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_MIGRATED' ).  lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_NO_INSTNR' ). lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_NO_SYSID' ).  lr_column->set_technical( abap_true ).
        lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_TLS' ).       lr_column->set_technical( abap_true ).
      endif.

      if P_TRUST is initial and P_DEST is initial.
        lr_column ?= lr_columns->get_column( 'RFC_ALLOWOLDTICKET4TT' ). lr_column->set_technical( abap_true ).
      endif.

    CATCH cx_salv_not_found.
  ENDTRY.

*... show it
  gr_alv_table->display( ).

ENDFORM.

form show_trusted_systems
  using
    column      type SALV_DE_COLUMN
    LLICENSE_NR type ts_result-install_number
    RFCTRUSTSY  type ts_result-sid
    .

    " Show trusted systems
    check column(12) = 'TRUSTSY_CNT_'
       or column = 'MUTUAL_TRUST_CNT'
       or column = 'NO_DATA_CNT'.

    data: ls_TRUSTED_SYSTEM  type ts_TRUSTED_SYSTEM.
    read table lt_TRUSTED_SYSTEMS ASSIGNING FIELD-SYMBOL(<fs_TRUSTED_SYSTEM>)
      WITH TABLE KEY
        RFCTRUSTSY  = RFCTRUSTSY
        LLICENSE_NR = LLICENSE_NR.
    check sy-subrc = 0.

    data:
      ls_RFCSYSACL_data type ts_RFCSYSACL_data,
      lt_RFCSYSACL_data type tt_RFCSYSACL_data.

    " ALV
    data:
      lr_table type ref to cl_salv_table.

    try.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lr_table
        CHANGING
          t_table      = lt_RFCSYSACL_data ).
      catch cx_salv_msg.
    endtry.

*... activate ALV generic Functions
    data(lr_functions) = lr_table->get_functions( ).
    lr_functions->set_all( abap_true ).

*... set the display settings
    data(lr_display) = lr_table->get_display_settings( ).
    TRY.
        "lr_display->set_list_header( sy-title ).
        "lr_display->set_list_header_size( CL_SALV_DISPLAY_SETTINGS=>C_HEADER_SIZE_LARGE ).
        lr_display->set_striped_pattern( abap_true ).
        lr_display->set_horizontal_lines( abap_true ).
        lr_display->set_vertical_lines( abap_true ).
        lr_display->set_suppress_empty_data( abap_true ).
      CATCH cx_salv_method_not_supported.
    ENDTRY.

*... set the functional settings
    data(lr_functional) = lr_table->get_functional_settings( ).
    TRY.
        lr_functional->set_sort_on_header_click( abap_true ).
        "lr_functional->set_f2_code( f2code ).
        "lr_functional->set_buffer( gs_test-settings-functional-buffer ).
      CATCH cx_salv_method_not_supported.
    ENDTRY.

* ...Set the layout
    "data(lr_layout) = lr_table->get_layout( ).
    "ls_layout_key-report = sy-repid.
    "lr_layout->set_key( ls_layout_key ).
    "lr_layout->set_initial_layout( P_LAYOUT ).
    "authority-check object 'S_ALV_LAYO'
    "                    id 'ACTVT' field '23'.
    "if sy-subrc = 0.
    "  lr_layout->set_save_restriction( cl_salv_layout=>restrict_none ) . "no restictions
    "else.
    "  lr_layout->set_save_restriction( cl_salv_layout=>restrict_user_dependant ) . "user dependend
    "endif.

*... sort

*... set column appearance
    data(lr_columns) = lr_table->get_columns( ).
    lr_columns->set_optimize( abap_true ). " Optimize column width

*... set the color of cells
    TRY.
        lr_columns->set_color_column( 'T_COLOR' ).
      CATCH cx_salv_data_error.                           "#EC NO_HANDLER
    ENDTRY.

    " Copy relevant data
    case column.
      when 'TRUSTSY_CNT_ALL'. " All trusted systems
        lr_display->set_list_header( `All trusted systems of system ` && RFCTRUSTSY ).

        loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data into ls_RFCSYSACL_data.
          append ls_RFCSYSACL_data to lt_RFCSYSACL_data.
        endloop.

      when 'NO_DATA_CNT'.   " No data for trusted system found
        lr_display->set_list_header( `No data for trusted system found of system ` && RFCTRUSTSY ).

        loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data into ls_RFCSYSACL_data
          where NO_DATA is not initial.
          append ls_RFCSYSACL_data to lt_RFCSYSACL_data.
        endloop.

      when 'MUTUAL_TRUST_CNT'.   " Mutual trust relations
        lr_display->set_list_header( `Mutual trust relations with system ` && RFCTRUSTSY ).

        loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data into ls_RFCSYSACL_data
          where MUTUAL_TRUST is not initial.
          append ls_RFCSYSACL_data to lt_RFCSYSACL_data.
        endloop.

      when 'TRUSTSY_CNT_TCD'. " Tcode active for trusted systems
        lr_display->set_list_header( `Tcode active for trusted systems of system ` && RFCTRUSTSY ).

        loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data into ls_RFCSYSACL_data
          where RFCTCDCHK = 'X'.
          append ls_RFCSYSACL_data to lt_RFCSYSACL_data.
        endloop.

      when 'TRUSTSY_CNT_3'.   " Migrated trusted systems
        lr_display->set_list_header( `Migrated trusted systems of system ` && RFCTRUSTSY ).

        loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data into ls_RFCSYSACL_data
          where RFCSLOPT(1) = '3'.
          append ls_RFCSYSACL_data to lt_RFCSYSACL_data.
        endloop.

      when 'TRUSTSY_CNT_2'.   " Old trusted systems
        lr_display->set_list_header( `Old trusted systems of system ` && RFCTRUSTSY ).

        loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data into ls_RFCSYSACL_data
          where RFCSLOPT(1) = '2'.
          append ls_RFCSYSACL_data to lt_RFCSYSACL_data.
        endloop.

      when 'TRUSTSY_CNT_1'.   " Very old trusted systems
        lr_display->set_list_header( `Very old trusted systems of system ` && RFCTRUSTSY ).

        loop at <fs_TRUSTED_SYSTEM>-RFCSYSACL_data into ls_RFCSYSACL_data
          where RFCSLOPT(1) = ' '.
          append ls_RFCSYSACL_data to lt_RFCSYSACL_data.
        endloop.

    endcase.

    " Set color
    loop at lt_RFCSYSACL_data ASSIGNING FIELD-SYMBOL(<fs_RFCSYSACL_data>).
      if <fs_RFCSYSACL_data>-MUTUAL_TRUST is not initial.
        APPEND VALUE #( fname = 'MUTUAL_TRUST' color-col = col_total ) TO <fs_RFCSYSACL_data>-t_color.
      endif.

      if <fs_RFCSYSACL_data>-RFCTCDCHK is not initial.
        APPEND VALUE #( fname = 'RFCTCDCHK' color-col = col_positive ) TO <fs_RFCSYSACL_data>-t_color.
      endif.

      if <fs_RFCSYSACL_data>-RFCSLOPT(1) = '3'.
        APPEND VALUE #( fname = 'RFCSLOPT' color-col = col_positive ) TO <fs_RFCSYSACL_data>-t_color.
      else.
        APPEND VALUE #( fname = 'RFCSLOPT' color-col = col_negative ) TO <fs_RFCSYSACL_data>-t_color.
      endif.
    endloop.

    TRY.
      data lr_column TYPE REF TO cl_salv_column_table.        " Columns in Simple, Two-Dimensional Tables

      lr_column ?= lr_columns->get_column( 'RFCSYSID' ).
      lr_column->set_long_text( 'Trusted system' ).
      lr_column->set_medium_text( 'Trusted system' ).
      lr_column->set_short_text( 'Trusted').

      lr_column ?= lr_columns->get_column( 'RFCTRUSTSY' ).
      lr_column->set_long_text( 'Trusting system' ).
      lr_column->set_medium_text( 'Trusting system' ).
      lr_column->set_short_text( 'Trusting').

      lr_column ?= lr_columns->get_column( 'RFCDEST' ).
      lr_column->set_long_text( 'Destination to trusted system' ).
      lr_column->set_medium_text( 'Dest. to trusted sys' ).
      lr_column->set_short_text( 'Dest.Trust').

      lr_column ?= lr_columns->get_column( 'RFCSLOPT' ).
      lr_column->set_long_text( 'Version: 3=migrated, 2=old,  =very old' ).
      lr_column->set_medium_text( 'Version' ).
      lr_column->set_short_text( 'Version').

      lr_column ?= lr_columns->get_column( 'NO_DATA' ).
      lr_column->set_long_text( 'No data of trusted system found' ).
      lr_column->set_medium_text( 'No data found' ).
      lr_column->set_short_text( 'No data' ).

      lr_column ?= lr_columns->get_column( 'MUTUAL_TRUST' ).
      lr_column->set_long_text( 'Mutual trust relation' ).
      lr_column->set_medium_text( 'Mutual trust' ).
      lr_column->set_short_text( 'Mutual').

      "lr_column ?= lr_columns->get_column( 'TLICENSE_NR' ).     lr_column->set_technical( abap_true ).
      "lr_column ?= lr_columns->get_column( 'LLICENSE_NR' ).     lr_column->set_technical( abap_true ).
      lr_column ?= lr_columns->get_column( 'RFCCREDEST' ).      lr_column->set_technical( abap_true ).
      lr_column ?= lr_columns->get_column( 'RFCREGDEST' ).      lr_column->set_technical( abap_true ).
      lr_column ?= lr_columns->get_column( 'RFCSNC' ).          lr_column->set_technical( abap_true ).
      "lr_column ?= lr_columns->get_column( 'RFCSECKEY' ).       lr_column->set_technical( abap_true ).

      CATCH cx_salv_not_found.
    ENDTRY.

    " Show it
    lr_table->display( ).

endform.

* Convert text like 'Dec  7 2020' into a date field
FORM convert_comp_time
  USING
    comp_time TYPE string
  CHANGING
    comp_date TYPE sy-datum.

  DATA:
    text     TYPE string,
    day(2)   TYPE n,
    month(2) TYPE n,
    year(4)  TYPE n.

  text = comp_time.
  CONDENSE text.
  SPLIT text AT space INTO DATA(month_c) DATA(day_c) DATA(year_c) DATA(time_c).
  day = day_c.
  CASE month_c.
    WHEN 'Jan'. month = 1.
    WHEN 'Feb'. month = 2.
    WHEN 'Mar'. month = 3.
    WHEN 'Apr'. month = 4.
    WHEN 'May'. month = 5.
    WHEN 'Jun'. month = 6.
    WHEN 'Jul'. month = 7.
    WHEN 'Aug'. month = 8.
    WHEN 'Sep'. month = 9.
    WHEN 'Oct'. month = 10.
    WHEN 'Nov'. month = 11.
    WHEN 'Dec'. month = 12.
  ENDCASE.
  year = year_c.
  comp_date = |{ year }{ month }{ day }|.
ENDFORM.