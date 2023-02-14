*&---------------------------------------------------------------------*
*& Report  ZCHECK_NOTE_3089413
*& Check implementation status of note 3089413 for connected ABAP systems
*&---------------------------------------------------------------------*
*& Author: Frank Buchholz, SAP CoE Security Services
*& Source: https://github.com/SAP-samples/security-services-tools
*&
*& 14.02.2023 A double click on a count of destinations shows a popup with the details
*& 13.02.2023 Refactoring to use local methods instead of forms
*& 07.02.2023 Show trusted systems without any data in RFCSYSACL
*&            Show mutual trust relations
*& 06.02.2023 New result field to indicate explicit selftrust defined in SMT1
*&            A double click on a count of trusted systems shows a popup with the details
*& 02.02.2023 Check destinations, too
*& 02.02.2023 Initial version
*&---------------------------------------------------------------------*
REPORT zcheck_note_3089413.

CONSTANTS: c_program_version(30) TYPE c VALUE '14.02.2023 FBT'.

TYPE-POOLS: icon, col, sym.

* System name
DATA sel_store_dir TYPE sdiagst_store_dir.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(30) ss_sid FOR FIELD p_sid.
SELECT-OPTIONS p_sid   FOR sel_store_dir-long_sid.
SELECTION-SCREEN END OF LINE.

* Check Kernel
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS       p_kern AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(33) ps_kern FOR FIELD p_kern.
SELECTION-SCREEN END OF LINE.

* Check ABAP
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS       p_abap AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(33) ps_abap FOR FIELD p_abap.
SELECTION-SCREEN END OF LINE.

* Check trusted relations
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS       p_trust AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(33) ps_trust FOR FIELD p_trust.
SELECTION-SCREEN END OF LINE.

* Check trusted destinations
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS       p_dest AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(33) ps_dest FOR FIELD p_dest.
SELECTION-SCREEN END OF LINE.
* Show specific type only if data found
DATA p_dest_3 TYPE abap_bool.
DATA p_dest_h TYPE abap_bool.
DATA p_dest_w TYPE abap_bool.

* Store status
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(30) ss_state FOR FIELD p_state.
SELECT-OPTIONS p_state FOR sel_store_dir-store_main_state_type." DEFAULT 'G'.
SELECTION-SCREEN END OF LINE.

* Layout of ALV output
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(33) ps_lout FOR FIELD p_layout.
PARAMETERS       p_layout TYPE disvariant-variant.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN COMMENT /1(60) ss_vers.

*---------------------------------------------------------------------*
*      CLASS lcl_report DEFINITION
*---------------------------------------------------------------------*
CLASS lcl_report DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS:

      initialization,

      f4_s_sid,

      f4_p_layout
        CHANGING layout TYPE disvariant-variant,

      at_selscr_on_p_layout
        IMPORTING layout TYPE disvariant-variant,

      start_of_selection.

  PRIVATE SECTION.

    TYPES:

      BEGIN OF ts_result,
        " Assumption: Match entries from different stores based on install_number and landscape_id

        install_number               TYPE sdiagst_store_dir-install_number,

        long_sid                     TYPE diagls_tech_syst_long_sid,    "sdiagst_store_dir-long_sid,
        sid                          TYPE diagls_technical_system_sid,  "sdiagst_store_dir-sid,
        tech_system_type             TYPE diagls_technical_system_type, "sdiagst_store_dir-tech_system_type,
        tech_system_id               TYPE diagls_id,                    "sdiagst_store_dir-tech_system_id,
        landscape_id                 TYPE diagls_id,                    "sdiagst_store_dir-landscape_id,
        host_full                    TYPE diagls_host_full_name,        "sdiagst_store_dir-host_full,
        host                         TYPE diagls_host_name,             "sdiagst_store_dir-host,
        host_id                      TYPE diagls_id,                    "sdiagst_store_dir-host_id,
        physical_host                TYPE diagls_host_name,             "sdiagst_store_dir-physical_host,
        instance_type                TYPE diagls_instance_type,         "sdiagst_store_dir-instance_type,
        instance                     TYPE diagls_instance_name,         "sdiagst_store_dir-instance,

        " Source store: we show the status of the first found store only which is usually store SAP_KERNEL
        compv_name                   TYPE sdiagst_store_dir-compv_name,

        " Source store: SAP_KERNEL
        kern_rel                     TYPE string,                               " 722_EXT_REL
        kern_patchlevel              TYPE string,                               " 1000
        kern_comp_time               TYPE string,                               " Jun  7 2020 15:44:10
        kern_comp_date               TYPE sy-datum,

        validate_kernel              TYPE string,

        " Source store: ABAP_COMP_SPLEVEL
        abap_release                 TYPE string,                               " 754
        abap_sp                      TYPE string,                               " 0032

        validate_abap                TYPE string,

        " Source store: ABAP_NOTES
        note_3089413                 TYPE string,
        note_3089413_prstatus        TYPE cwbprstat,
        note_3287611                 TYPE string,
        note_3287611_prstatus        TYPE cwbprstat,

        " Source store: RFCSYSACL
        trustsy_cnt_all              TYPE i,
        no_data_cnt                  TYPE i,
        mutual_trust_cnt             TYPE i,
        trustsy_cnt_tcd              TYPE i,
        trustsy_cnt_3                TYPE i,
        trustsy_cnt_2                TYPE i,
        trustsy_cnt_1                TYPE i,
        explicit_selftrust           TYPE string,

        " Source store: ABAP_INSTANMCE_PAHI
        rfc_selftrust                TYPE string,
        rfc_allowoldticket4tt        TYPE string,
        rfc_sendinstnr4tt            TYPE string,

        " Source store: RFCDES
        dest_3_cnt_all               TYPE i,
        dest_3_cnt_trusted           TYPE i,
        dest_3_cnt_trusted_migrated  TYPE i,
        dest_3_cnt_trusted_no_instnr TYPE i,
        dest_3_cnt_trusted_no_sysid  TYPE i,
        dest_3_cnt_trusted_snc       TYPE i,

        dest_h_cnt_all               TYPE i,
        dest_h_cnt_trusted           TYPE i,
        dest_h_cnt_trusted_migrated  TYPE i,
        dest_h_cnt_trusted_no_instnr TYPE i,
        dest_h_cnt_trusted_no_sysid  TYPE i,
        dest_h_cnt_trusted_tls       TYPE i,

        dest_w_cnt_all               TYPE i,
        dest_w_cnt_trusted           TYPE i,
        dest_w_cnt_trusted_migrated  TYPE i,
        dest_w_cnt_trusted_no_instnr TYPE i,
        dest_w_cnt_trusted_no_sysid  TYPE i,
        dest_w_cnt_trusted_tls       TYPE i,

        " Source store: we show the status of the first found store only which is usually store SAP_KERNEL
        store_id                     TYPE sdiagst_store_dir-store_id,
        store_last_upload            TYPE sdiagst_store_dir-store_last_upload,
        store_state                  TYPE sdiagst_store_dir-store_state,           " CMPL = ok
        store_main_state_type        TYPE sdiagst_store_dir-store_main_state_type, " (G)reen, (Y)ello, (R)ed, (N)ot relevant
        store_main_state             TYPE sdiagst_store_dir-store_main_state,
        store_outdated_day           TYPE sdiagst_store_dir-store_outdated_day,

        t_color                      TYPE lvc_t_scol,
        "t_celltype                   type salv_t_int4_column,
        "T_HYPERLINK                  type SALV_T_INT4_COLUMN,
        "t_dropdown                   type salv_t_int4_column,
      END OF ts_result,
      tt_result TYPE STANDARD TABLE OF ts_result.

    CLASS-DATA:
      lt_result TYPE tt_result,
      ls_result TYPE ts_result.

    " Popup showing trusted systems
    TYPES:
      BEGIN OF ts_rfcsysacl_data,
        rfcsysid     TYPE rfcssysid,  " Trusted system
        tlicense_nr  TYPE slic_inst,  " Installation number of trusted system

        rfctrustsy   TYPE rfcssysid,  " Trusting system (=current system)
        llicense_nr  TYPE slic_inst,  " Installation number of trusting system (=current system), only available in higher versions

        rfcdest      TYPE rfcdest,    " Destination to trusted system
        rfccredest   TYPE rfcdest,    " Destination, only available in higher versions
        rfcregdest   TYPE rfcdest,    " Destination, only available in higher versions

        rfcsnc       TYPE rfcsnc,     " SNC respective TLS
        rfcseckey    TYPE rfcticket,  " Security key (empty or '(stored)'), only available in higher versions
        rfctcdchk    TYPE rfctcdchk,  " Tcode check
        rfcslopt     TYPE rfcslopt,   " Options respective version

        no_data      TYPE string,    " No data found for trusted system
        mutual_trust TYPE string,    " Mutual trus relation

        t_color      TYPE lvc_t_scol,
      END OF ts_rfcsysacl_data,
      tt_rfcsysacl_data TYPE STANDARD TABLE OF ts_rfcsysacl_data WITH KEY rfcsysid tlicense_nr,

      BEGIN OF ts_trusted_system,
        rfctrustsy     TYPE rfcssysid,  " Trusting system (=current system)
        llicense_nr    TYPE slic_inst,  " Installation number of trusting system
        rfcsysacl_data TYPE tt_rfcsysacl_data,
      END OF ts_trusted_system,
      tt_trusted_systems TYPE STANDARD TABLE OF ts_trusted_system WITH KEY rfctrustsy llicense_nr.

    CLASS-DATA:
      ls_trusted_system  TYPE ts_trusted_system,
      lt_trusted_systems TYPE tt_trusted_systems.

    " Popup showing destinations
    TYPES:
      BEGIN OF ts_destination_data,
        rfcdest        TYPE rfcdest,
        rfctype        TYPE RFCTYPE_D,
        trusted(1),                                           " Flag for Trusted RFC
        sysid          TYPE diagls_technical_system_sid,      " System ID of target system
        instnr         TYPE sdiagst_store_dir-install_number, " Installation number of target system
        encrypted(1),                                         " Flag for SNC / TLS

        t_color      TYPE lvc_t_scol,
      END OF ts_destination_data,
      tt_destination_data TYPE STANDARD TABLE OF ts_destination_data WITH KEY rfcdest,

      BEGIN OF ts_destination,
        sid            TYPE diagls_technical_system_sid,  "sdiagst_store_dir-sid,
        install_number TYPE sdiagst_store_dir-install_number,
        destination_data    TYPE tt_destination_data,
      END OF ts_destination,
      tt_destinations TYPE STANDARD TABLE OF ts_destination WITH KEY sid install_number.

    CLASS-DATA:
      ls_destination  TYPE ts_destination,
      lt_destinations TYPE tt_destinations.

    CLASS-METHODS:

      get_sap_kernel,

      " Convert text like 'Dec  7 2020' into a date field
      convert_comp_time
        IMPORTING comp_time        TYPE string
        RETURNING VALUE(comp_date) TYPE sy-datum,

      get_abap_comp_splevel,

      get_abap_notes,

      get_rfcsysacl,

      get_rfcdes,

      get_abap_instance_pahi,

      validate_kernel,

      validate_abap,

      validate_mutual_trust,

      show_result,

      on_user_command FOR EVENT added_function OF cl_salv_events
        IMPORTING e_salv_function,

      on_double_click FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column,

*      on_single_click for event link_click of cl_salv_events_table
*        importing row column,

      show_trusted_systems
        IMPORTING
          column      TYPE salv_de_column
          llicense_nr TYPE ts_result-install_number
          rfctrustsy  TYPE ts_result-sid,

      show_destinations
        IMPORTING
          column      TYPE salv_de_column
          install_number TYPE ts_result-install_number
          sid         TYPE ts_result-sid.

    CLASS-DATA:

      ls_alv_variant TYPE disvariant,

      " main data table
      lr_alv_table   TYPE REF TO cl_salv_table,

      " for handling the events of cl_salv_table
      lr_alv_events  TYPE REF TO lcl_report.

ENDCLASS.                    "lcl_report DEFINITION

*----------------------------------------------------------------------*
*      CLASS lcl_report IMPLEMENTATION
*----------------------------------------------------------------------*
CLASS lcl_report IMPLEMENTATION.

  METHOD initialization.

    sy-title = 'Check implementation status of note 3089413 for connected ABAP systems'(TIT).

    ss_sid   = 'System'.
    ss_state = 'Config. store status (G/Y/R)'.

    ps_kern  = 'Check Kernel'.
    ps_abap  = 'Check Support Package and Notes'.
    ps_trust = 'Check Trusted Relations'.
    ps_dest  = 'Check Trusted Destinations'.

    ps_lout     = 'Layout'(t18).

    CONCATENATE 'Program version:'(ver) c_program_version INTO ss_vers
       SEPARATED BY space.

  ENDMETHOD. " initialization

  METHOD f4_s_sid.

    TYPES:
      BEGIN OF ts_f4_value,
        long_sid       TYPE diagls_tech_syst_long_sid,    "sdiagst_store_dir-long_sid,
        "sid                   TYPE diagls_technical_system_sid,  "sdiagst_store_dir-sid,
        "tech_system_id        TYPE diagls_id,                    "sdiagst_store_dir-tech_system_id,
        install_number TYPE diagls_tech_syst_install_nbr,
        itadmin_role   TYPE diagls_itadmin_role,
      END OF ts_f4_value.

    DATA:
      f4_value     TYPE          ts_f4_value,
      f4_value_tab TYPE TABLE OF ts_f4_value.

    DATA:
      lt_technical_systems TYPE  tt_diagst_tech_syst,
      rc                   TYPE  i,
      rc_text              TYPE  natxt.

    CALL FUNCTION 'DIAGST_GET_TECH_SYSTEMS'
      EXPORTING
        namespace         = 'ACTIVE'
*       LONG_SID          =
        tech_type         = 'ABAP'
*       INSTALL_NUMBER    =
*       TECH_SYST_ID      =
*       DIAG_RELEVANT     = 'X'
*       STATS_FROM        =
*       STATS_TO          =
*       DISPLAY           = ' '                        " Only useful if the function is manually executed by transaction SE37.
        " Setting this parameter to �X� will display the result.
*       CALLING_APPL      = ' '
      IMPORTING
        technical_systems = lt_technical_systems
*       STATS             =
        rc                = rc
        rc_text           = rc_text.

    LOOP AT lt_technical_systems INTO DATA(ls_technical_systems).
      MOVE-CORRESPONDING ls_technical_systems TO f4_value.
      APPEND f4_value TO f4_value_tab.
    ENDLOOP.
    SORT f4_value_tab BY long_sid.

    DATA(progname) = sy-repid.
    DATA(dynnum)   = sy-dynnr.
    DATA field TYPE dynfnam.
    DATA stepl TYPE sy-stepl.
    GET CURSOR FIELD field LINE stepl.
    DATA return_tab TYPE TABLE OF ddshretval.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'LONG_SID'
        dynpprog        = progname
        dynpnr          = dynnum
        dynprofield     = field
        stepl           = stepl
        value_org       = 'S'
      TABLES
*       field_tab       = field_tab
        value_tab       = f4_value_tab
        return_tab      = return_tab " surprisingly required to get lower case values
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2.
    IF sy-subrc <> 0.
*   Implement suitable error handling here
    ENDIF.

  ENDMETHOD. " f4_s_sid

  METHOD f4_p_layout.
    "CHANGING layout TYPE disvariant-variant.

    ls_alv_variant-report  = sy-repid.
    ls_alv_variant-variant = layout.

    CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
      EXPORTING
        is_variant    = ls_alv_variant
        i_save        = 'A'
      IMPORTING
        es_variant    = ls_alv_variant
      EXCEPTIONS
        not_found     = 1
        program_error = 2
        OTHERS        = 3.

    IF sy-subrc = 0.
      layout = ls_alv_variant-variant.
    ELSE.
      MESSAGE s073(0k). " Keine Anzeigevariante(n) vorhanden
    ENDIF.

  ENDMETHOD. " f4_p_layout

  METHOD at_selscr_on_p_layout.
    "IMPORTING layout TYPE disvariant-variant.

    DATA: ls_variant TYPE disvariant.

    ls_variant-report  = sy-repid.
    ls_variant-variant = layout.

    CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
      EXPORTING
        i_save        = 'A'
      CHANGING
        cs_variant    = ls_variant
      EXCEPTIONS
        wrong_input   = 1
        not_found     = 2
        program_error = 3
        OTHERS        = 4.

    IF sy-subrc <> 0.
*   Selected layout variant is not found
      MESSAGE e204(0k).
    ENDIF.

    ls_alv_variant-report  = sy-repid.
    ls_alv_variant-variant = layout.

  ENDMETHOD. " at_selscr_on_p_layout

  METHOD start_of_selection.

    get_sap_kernel( ).         " Kernel version
    get_abap_comp_splevel( ).  " Support Package version of SAP_BASIS
    get_abap_notes( ).         " Notes 3089413 and 3287611
    get_rfcsysacl( ).          " Trusting relations
    get_rfcdes( ).             " Trusted desinations
    get_abap_instance_pahi( ). " rfc/selftrust

    validate_kernel( ).
    validate_abap( ).

    validate_mutual_trust( ).

    show_result( ).

  ENDMETHOD. " start_of_selection

  METHOD get_sap_kernel.
    CHECK p_kern = 'X'.

    " Same as in report ZSHOW_KERNEL_STORES but one one entry per system

    DATA:
      lt_store_dir_tech TYPE  tt_diagst_store_dir_tech,
      lt_store_dir      TYPE  tt_diagst_store_dir,
      lt_fieldlist      TYPE  tt_diagst_table_store_fields,
      lt_snapshot       TYPE  tt_diagst_trows,
      rc                TYPE  i,
      rc_text           TYPE  natxt.

    DATA: tabix TYPE i.

    CALL FUNCTION 'DIAGST_GET_STORES'
      EXPORTING
        " The �System Filter� parameters allow to get all Stores of a system or technical system.
        " Some combinations of the four parameters are not allowed.
        " The function will return an error code in such a case.
*       SID                   = ' '
*       INSTALL_NUMBER        = ' '
*       LONG_SID              = ' '
*       TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)
        " Store key fields
        group_namespace       = 'ACTIVE'                   "(optional)
        group_landscape_class = 'CL_DIAGLS_ABAP_INSTANCE'  "(optional)
*       GROUP_LANDSCAPE_ID    = ' '
*       GROUP_COMP_ID         = ' '
        group_source          = 'ABAP'                     "(optional)
        group_name            = 'INSTANCE'                 "(optional)
        store_category        = 'SOFTWARE'                 "(optional)
        store_type            = 'PROPERTY'                 "(optional)
*       STORE_FULLPATH        = ' '
        store_name            = 'SAP_KERNEL'
        " Special filters
        store_mainalias       = 'ABAP-SOFTWARE'            "(optional)
        store_subalias        = 'SAP-KERNEL'               "(optional)
*       STORE_TPL_ID          = ' '
*       HAS_ELEMENT_FROM      =                            " date range
*       HAS_ELEMENT_TO        =                            " date range
*       ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*       CASE_INSENSITIVE      = ' '
*       PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*       SEARCH_STRING         =
*       ONLY_RELEVANT         = 'X'
*       PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll
        " Others
*       DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
        " Setting this parameter to �X� will display the result.
*       CALLING_APPL          = ' '
      IMPORTING
*       STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
        store_dir             = lt_store_dir               "(not recommended anymore)
*       STORE_DIR_MI          =                            "(SAP internal usage only)
*       STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*       PARAMETER             =                            "(SAP internal usage only)
        rc                    = rc
        rc_text               = rc_text.

    IF rc IS NOT INITIAL.
      MESSAGE e001(00) WITH rc_text.
    ENDIF.

    LOOP AT lt_store_dir INTO DATA(ls_store_dir)
      WHERE long_sid              IN p_sid
        AND store_main_state_type IN p_state
      .

      " Do we already have an entry for this system?
      READ TABLE lt_result INTO ls_result
        WITH KEY
          install_number = ls_store_dir-install_number
          long_sid       = ls_store_dir-long_sid
          sid            = ls_store_dir-sid
          .
      IF sy-subrc = 0.
        tabix = sy-tabix.
        IF ls_store_dir-instance_type NE 'CENTRAL'.
          CONTINUE.
        ENDIF.
        MOVE-CORRESPONDING ls_store_dir TO ls_result.
      ELSE.
        tabix = -1.
        CLEAR ls_result.
        MOVE-CORRESPONDING ls_store_dir TO ls_result.
      ENDIF.

      IF ls_result-host_full IS INITIAL.
        ls_result-host_full = ls_result-host. " host, host_id, physical_host
      ENDIF.

      CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
        EXPORTING
          store_id  = ls_store_dir-store_id
*         TIMESTAMP =                        " if not specified the latest available snapshot is returned
*         CALLING_APPL                = ' '
        IMPORTING
          fieldlist = lt_fieldlist
*         SNAPSHOT_VALID_FROM         =
*         SNAPSHOT_VALID_TO_CONFIRMED =
*         SNAPSHOT_VALID_TO           =
          snapshot  = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*         SNAPSHOT_TR                 =
*         SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
          rc        = rc                     " 3: Permission denied, Content Authorization missing
          " 4: Store not existing
          " 8: Error
          rc_text   = rc_text.

      LOOP AT lt_snapshot INTO DATA(lt_snapshot_elem).
        READ TABLE lt_snapshot_elem INTO DATA(ls_parameter) INDEX 1.
        CHECK ls_parameter-fieldname = 'PARAMETER'.

        READ TABLE lt_snapshot_elem INTO DATA(ls_value)     INDEX 2.
        CHECK ls_value-fieldname = 'VALUE'.

        CASE ls_parameter-fieldvalue.

          WHEN 'KERN_COMP_ON'.      " Linux GNU SLES-11 x86_64 cc4.3.4 use-pr190909
            " not used yet

          WHEN 'KERN_COMP_TIME'.    " Jun  7 2020 15:44:10
            ls_result-kern_comp_time  = ls_value-fieldvalue.
            ls_result-kern_comp_date  = convert_comp_time( ls_result-kern_comp_time ).

          WHEN 'KERN_DBLIB'.        " SQLDBC 7.9.8.040
            " not used yet

          WHEN 'KERN_PATCHLEVEL'.   " 1000
            ls_result-kern_patchlevel = ls_value-fieldvalue.

          WHEN 'KERN_REL'.          " 722_EXT_REL
            ls_result-kern_rel        = ls_value-fieldvalue.

          WHEN 'PLATFORM-ID'.       " 390
            " not used yet

        ENDCASE.
      ENDLOOP.

      IF tabix > 0.
        MODIFY lt_result FROM ls_result INDEX tabix.
      ELSE.
        APPEND ls_result TO lt_result.
      ENDIF.

    ENDLOOP. " lt_STORE_DIR

  ENDMETHOD. " get_SAP_KERNEL

* Convert text like 'Dec  7 2020' into a date field
  METHOD convert_comp_time.
    "IMPORTING comp_time TYPE string
    "RETURNING VALUE(comp_date) TYPE sy-datum

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
  ENDMETHOD. " convert_comp_time

  METHOD get_abap_comp_splevel.
    CHECK p_abap = 'X'.

    DATA:
      lt_store_dir_tech TYPE  tt_diagst_store_dir_tech,
      lt_store_dir      TYPE  tt_diagst_store_dir,
      lt_fieldlist      TYPE  tt_diagst_table_store_fields,
      lt_snapshot       TYPE  tt_diagst_trows,
      rc                TYPE  i,
      rc_text           TYPE  natxt.

    DATA: tabix TYPE i.

    " Using a SEARCH_STRING for SAP_BASIS should not speed up processing, as this component exists always
    CALL FUNCTION 'DIAGST_GET_STORES'
      EXPORTING
        " The �System Filter� parameters allow to get all Stores of a system or technical system.
        " Some combinations of the four parameters are not allowed.
        " The function will return an error code in such a case.
*       SID                   = ' '
*       INSTALL_NUMBER        = ' '
*       LONG_SID              = ' '
*       TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)
        " Store key fields
        group_namespace       = 'ACTIVE'                   "(optional)
        group_landscape_class = 'CL_DIAGLS_ABAP_TECH_SYST' "(optional)
*       GROUP_LANDSCAPE_ID    = ' '
*       GROUP_COMP_ID         = ' '
        group_source          = 'ABAP'                     "(optional)
        group_name            = 'ABAP-SOFTWARE'            "(optional)
        store_category        = 'SOFTWARE'                 "(optional)
        store_type            = 'TABLE'                    "(optional)
*       STORE_FULLPATH        = ' '
        store_name            = 'ABAP_COMP_SPLEVEL'
        " Special filters
        store_mainalias       = 'ABAP-SOFTWARE'            "(optional)
        store_subalias        = 'SUPPORT-PACKAGE-LEVEL'    "(optional)
*       STORE_TPL_ID          = ' '
*       HAS_ELEMENT_FROM      =                            " date range
*       HAS_ELEMENT_TO        =                            " date range
*       ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*       CASE_INSENSITIVE      = ' '
        "PATTERN_SEARCH        = ' '                        " Allow pattern search for SEARCH_STRING
        "SEARCH_STRING         = 'SAP_BASIS'
*       ONLY_RELEVANT         = 'X'
*       PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll
        " Others
*       DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
        " Setting this parameter to �X� will display the result.
*       CALLING_APPL          = ' '
      IMPORTING
*       STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
        store_dir             = lt_store_dir               "(not recommended anymore)
*       STORE_DIR_MI          =                            "(SAP internal usage only)
*       STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*       PARAMETER             =                            "(SAP internal usage only)
        rc                    = rc
        rc_text               = rc_text.

    IF rc IS NOT INITIAL.
      MESSAGE e001(00) WITH rc_text.
    ENDIF.

    LOOP AT lt_store_dir INTO DATA(ls_store_dir)
      WHERE long_sid              IN p_sid
        AND store_main_state_type IN p_state
      .

      " Do we already have an entry for this system?
      READ TABLE lt_result INTO ls_result
        WITH KEY
          install_number = ls_store_dir-install_number
          long_sid       = ls_store_dir-long_sid
          sid            = ls_store_dir-sid
          .
      IF sy-subrc = 0.
        tabix = sy-tabix.
      ELSE.
        tabix = -1.
        CLEAR ls_result.
        MOVE-CORRESPONDING ls_store_dir TO ls_result.
      ENDIF.

      CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
        EXPORTING
          store_id  = ls_store_dir-store_id
*         TIMESTAMP =                        " if not specified the latest available snapshot is returned
*         CALLING_APPL                = ' '
        IMPORTING
          fieldlist = lt_fieldlist
*         SNAPSHOT_VALID_FROM         =
*         SNAPSHOT_VALID_TO_CONFIRMED =
*         SNAPSHOT_VALID_TO           =
          snapshot  = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*         SNAPSHOT_TR                 =
*         SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
          rc        = rc                     " 3: Permission denied, Content Authorization missing
          " 4: Store not existing
          " 8: Error
          rc_text   = rc_text.

      LOOP AT lt_snapshot INTO DATA(lt_snapshot_elem).
        READ TABLE lt_snapshot_elem INTO DATA(ls_component)  INDEX 1.
        CHECK ls_component-fieldname = 'COMPONENT'.
        CHECK ls_component-fieldvalue = 'SAP_BASIS'.

        READ TABLE lt_snapshot_elem INTO DATA(ls_release)    INDEX 2.
        CHECK ls_release-fieldname = 'RELEASE'.
        ls_result-abap_release = ls_release-fieldvalue.

        READ TABLE lt_snapshot_elem INTO DATA(ls_extrelease) INDEX 3.
        CHECK ls_extrelease-fieldname = 'EXTRELEASE'.
        ls_result-abap_sp      = ls_extrelease-fieldvalue.
      ENDLOOP.

      IF tabix > 0.
        MODIFY lt_result FROM ls_result INDEX tabix.
      ELSE.
        APPEND ls_result TO lt_result.
      ENDIF.

    ENDLOOP. " lt_STORE_DIR

  ENDMETHOD. " get_ABAP_COMP_SPLEVEL

  METHOD get_abap_notes.
    CHECK p_abap = 'X'.

    DATA:
      lt_store_dir_tech TYPE  tt_diagst_store_dir_tech,
      lt_store_dir      TYPE  tt_diagst_store_dir,
      lt_fieldlist      TYPE  tt_diagst_table_store_fields,
      lt_snapshot       TYPE  tt_diagst_trows,
      rc                TYPE  i,
      rc_text           TYPE  natxt.

    DATA: tabix TYPE i.

    " Maybe it' faster to call it twice including a SEARCH_STRING for both note numbers.
    CALL FUNCTION 'DIAGST_GET_STORES'
      EXPORTING
        " The �System Filter� parameters allow to get all Stores of a system or technical system.
        " Some combinations of the four parameters are not allowed.
        " The function will return an error code in such a case.
*       SID                   = ' '
*       INSTALL_NUMBER        = ' '
*       LONG_SID              = ' '
*       TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)
        " Store key fields
        group_namespace       = 'ACTIVE'                   "(optional)
        group_landscape_class = 'CL_DIAGLS_ABAP_TECH_SYST' "(optional)
*       GROUP_LANDSCAPE_ID    = ' '
*       GROUP_COMP_ID         = ' '
        group_source          = 'ABAP'                     "(optional)
        group_name            = 'ABAP-SOFTWARE'            "(optional)
        store_category        = 'SOFTWARE'                 "(optional)
        store_type            = 'TABLE'                    "(optional)
*       STORE_FULLPATH        = ' '
        store_name            = 'ABAP_NOTES'
        " Special filters
        store_mainalias       = 'ABAP-SOFTWARE'            "(optional)
        store_subalias        = 'ABAP-NOTES'               "(optional)
*       STORE_TPL_ID          = ' '
*       HAS_ELEMENT_FROM      =                            " date range
*       HAS_ELEMENT_TO        =                            " date range
*       ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*       CASE_INSENSITIVE      = ' '
*       PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*       SEARCH_STRING         =
*       ONLY_RELEVANT         = 'X'
*       PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll
        " Others
*       DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
        " Setting this parameter to �X� will display the result.
*       CALLING_APPL          = ' '
      IMPORTING
*       STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
        store_dir             = lt_store_dir               "(not recommended anymore)
*       STORE_DIR_MI          =                            "(SAP internal usage only)
*       STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*       PARAMETER             =                            "(SAP internal usage only)
        rc                    = rc
        rc_text               = rc_text.

    IF rc IS NOT INITIAL.
      MESSAGE e001(00) WITH rc_text.
    ENDIF.

    LOOP AT lt_store_dir INTO DATA(ls_store_dir)
      WHERE long_sid              IN p_sid
        AND store_main_state_type IN p_state
      .

      " Do we already have an entry for this system?
      READ TABLE lt_result INTO ls_result
        WITH KEY
          install_number = ls_store_dir-install_number
          long_sid       = ls_store_dir-long_sid
          sid            = ls_store_dir-sid
          .
      IF sy-subrc = 0.
        tabix = sy-tabix.
      ELSE.
        tabix = -1.
        CLEAR ls_result.
        MOVE-CORRESPONDING ls_store_dir TO ls_result.
      ENDIF.

      CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
        EXPORTING
          store_id  = ls_store_dir-store_id
*         TIMESTAMP =                        " if not specified the latest available snapshot is returned
*         CALLING_APPL                = ' '
        IMPORTING
          fieldlist = lt_fieldlist
*         SNAPSHOT_VALID_FROM         =
*         SNAPSHOT_VALID_TO_CONFIRMED =
*         SNAPSHOT_VALID_TO           =
          snapshot  = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*         SNAPSHOT_TR                 =
*         SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
          rc        = rc                     " 3: Permission denied, Content Authorization missing
          " 4: Store not existing
          " 8: Error
          rc_text   = rc_text.

      LOOP AT lt_snapshot INTO DATA(lt_snapshot_elem).
        READ TABLE lt_snapshot_elem INTO DATA(ls_note)      INDEX 1. "
        CHECK ls_note-fieldname = 'NOTE'.
        CHECK ls_note-fieldvalue = '0003089413'
           OR ls_note-fieldvalue = '0003287611'.

        READ TABLE lt_snapshot_elem INTO DATA(ls_version)   INDEX 2. "
        CHECK ls_version-fieldname = 'VERSION'.

        "READ TABLE lt_snapshot_elem INTO data(ls_TEXT)      INDEX 3. "
        "check ls_TEXT-fieldname = 'TEXT'.

        READ TABLE lt_snapshot_elem INTO DATA(ls_prstatust) INDEX 4. "
        CHECK ls_prstatust-fieldname = 'PRSTATUST'.

        READ TABLE lt_snapshot_elem INTO DATA(ls_prstatus)  INDEX 5. "
        CHECK ls_prstatus-fieldname = 'PRSTATUS'.

        DATA(status) = ls_prstatust-fieldvalue && ` version ` && ls_version-fieldvalue.
        CASE ls_note-fieldvalue.
          WHEN '0003089413'.
            ls_result-note_3089413 = status.
            ls_result-note_3089413_prstatus = ls_prstatus-fieldvalue.
          WHEN '0003287611'.
            ls_result-note_3287611 = status.
            ls_result-note_3287611_prstatus = ls_prstatus-fieldvalue.
        ENDCASE.

      ENDLOOP.

      IF tabix > 0.
        MODIFY lt_result FROM ls_result INDEX tabix.
      ELSE.
        APPEND ls_result TO lt_result.
      ENDIF.

    ENDLOOP. " lt_STORE_DIR

  ENDMETHOD. " get_ABAP_NOTES

  METHOD get_rfcsysacl.
    CHECK p_trust = 'X'.

    DATA:
      lt_store_dir_tech TYPE  tt_diagst_store_dir_tech,
      lt_store_dir      TYPE  tt_diagst_store_dir,
      lt_fieldlist      TYPE  tt_diagst_table_store_fields,
      lt_snapshot       TYPE  tt_diagst_trows,
      rc                TYPE  i,
      rc_text           TYPE  natxt.

    DATA: tabix TYPE i.

    CALL FUNCTION 'DIAGST_GET_STORES'
      EXPORTING
        " The �System Filter� parameters allow to get all Stores of a system or technical system.
        " Some combinations of the four parameters are not allowed.
        " The function will return an error code in such a case.
*       SID                   = ' '
*       INSTALL_NUMBER        = ' '
*       LONG_SID              = ' '
*       TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)
        " Store key fields
        group_namespace       = 'ACTIVE'                   "(optional)
        group_landscape_class = 'CL_DIAGLS_ABAP_TECH_SYST' "(optional)
*       GROUP_LANDSCAPE_ID    = ' '
*       GROUP_COMP_ID         = ' '
        group_source          = 'ABAP'                     "(optional)
        group_name            = 'ABAP-SECURITY'            "(optional)
        store_category        = 'CONFIG'                   "(optional)
        store_type            = 'TABLE'                    "(optional)
*       STORE_FULLPATH        = ' '
        store_name            = 'RFCSYSACL'
        " Special filters
        store_mainalias       = 'SECURITY'                 "(optional)
        store_subalias        = 'TRUSTED RFC'              "(optional)
*       STORE_TPL_ID          = ' '
*       HAS_ELEMENT_FROM      =                            " date range
*       HAS_ELEMENT_TO        =                            " date range
*       ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*       CASE_INSENSITIVE      = ' '
*       PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*       SEARCH_STRING         =
*       ONLY_RELEVANT         = 'X'
*       PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll
        " Others
*       DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
        " Setting this parameter to �X� will display the result.
*       CALLING_APPL          = ' '
      IMPORTING
*       STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
        store_dir             = lt_store_dir               "(not recommended anymore)
*       STORE_DIR_MI          =                            "(SAP internal usage only)
*       STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*       PARAMETER             =                            "(SAP internal usage only)
        rc                    = rc
        rc_text               = rc_text.

    IF rc IS NOT INITIAL.
      MESSAGE e001(00) WITH rc_text.
    ENDIF.

    LOOP AT lt_store_dir INTO DATA(ls_store_dir)
      WHERE long_sid              IN p_sid
        AND store_main_state_type IN p_state
      .

      " Do we already have an entry for this system?
      READ TABLE lt_result INTO ls_result
        WITH KEY
          install_number = ls_store_dir-install_number
          long_sid       = ls_store_dir-long_sid
          sid            = ls_store_dir-sid
          .
      IF sy-subrc = 0.
        tabix = sy-tabix.
      ELSE.
        tabix = -1.
        CLEAR ls_result.
        MOVE-CORRESPONDING ls_store_dir TO ls_result.
      ENDIF.

      CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
        EXPORTING
          store_id  = ls_store_dir-store_id
*         TIMESTAMP =                        " if not specified the latest available snapshot is returned
*         CALLING_APPL                = ' '
        IMPORTING
          fieldlist = lt_fieldlist
*         SNAPSHOT_VALID_FROM         =
*         SNAPSHOT_VALID_TO_CONFIRMED =
*         SNAPSHOT_VALID_TO           =
          snapshot  = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*         SNAPSHOT_TR                 =
*         SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
          rc        = rc                     " 3: Permission denied, Content Authorization missing
          " 4: Store not existing
          " 8: Error
          rc_text   = rc_text.

      " Store RRFCSYSACL data
      CLEAR ls_trusted_system.
      ls_trusted_system-rfctrustsy  = ls_store_dir-sid.
      ls_trusted_system-llicense_nr = ls_store_dir-install_number.

      LOOP AT lt_snapshot INTO DATA(lt_snapshot_elem).

        " Store RRFCSYSACL data
        DATA ls_rfcsysacl_data TYPE ts_rfcsysacl_data.
        CLEAR ls_rfcsysacl_data.

        LOOP AT lt_snapshot_elem INTO DATA(snapshot_elem).
          IF snapshot_elem-fieldvalue = '<CCDB NULL>'.
            CLEAR snapshot_elem-fieldvalue.
          ENDIF.

          CASE snapshot_elem-fieldname.
            WHEN 'RFCSYSID'.    ls_rfcsysacl_data-rfcsysid    = snapshot_elem-fieldvalue. " 1
            WHEN 'TLICENSE_NR'. ls_rfcsysacl_data-tlicense_nr = snapshot_elem-fieldvalue. " 2
            WHEN 'RFCTRUSTSY'.  ls_rfcsysacl_data-rfctrustsy  = snapshot_elem-fieldvalue. " 3
            WHEN 'RFCDEST'.     ls_rfcsysacl_data-rfcdest     = snapshot_elem-fieldvalue. " 4
            WHEN 'RFCTCDCHK'.   ls_rfcsysacl_data-rfctcdchk   = snapshot_elem-fieldvalue. " 5
            WHEN 'RFCSNC'.      ls_rfcsysacl_data-rfcsnc      = snapshot_elem-fieldvalue. " 6
            WHEN 'RFCSLOPT'.    ls_rfcsysacl_data-rfcslopt    = snapshot_elem-fieldvalue. " 7
              " only available in higher versions
            WHEN 'RFCCREDEST'.  ls_rfcsysacl_data-rfccredest  = snapshot_elem-fieldvalue. " 8
            WHEN 'RFCREGDEST'.  ls_rfcsysacl_data-rfcregdest  = snapshot_elem-fieldvalue. " 9
            WHEN 'LLICENSE_NR'. ls_rfcsysacl_data-llicense_nr = snapshot_elem-fieldvalue. " 10
            WHEN 'RFCSECKEY'.   ls_rfcsysacl_data-rfcseckey   = snapshot_elem-fieldvalue. " 11
          ENDCASE.
        ENDLOOP.

        " Add installation number
        IF ls_rfcsysacl_data-llicense_nr IS INITIAL.
          ls_rfcsysacl_data-llicense_nr = ls_trusted_system-llicense_nr.
        ENDIF.

        " Store RRFCSYSACL data
        APPEND ls_rfcsysacl_data TO ls_trusted_system-rfcsysacl_data.

        ADD 1 TO ls_result-trustsy_cnt_all.

        IF ls_rfcsysacl_data-rfctcdchk IS NOT INITIAL.
          ADD 1 TO ls_result-trustsy_cnt_tcd.
        ENDIF.

        " Get version
        DATA version(1).
        version = ls_rfcsysacl_data-rfcslopt. " get first char of the string
        CASE version.
          WHEN '3'. ADD 1 TO ls_result-trustsy_cnt_3.
          WHEN '2'. ADD 1 TO ls_result-trustsy_cnt_2.
          WHEN ' '. ADD 1 TO ls_result-trustsy_cnt_1.
        ENDCASE.

        " Identify selftrust
        IF ls_rfcsysacl_data-rfcsysid = ls_rfcsysacl_data-rfctrustsy.
          IF ls_rfcsysacl_data-llicense_nr IS NOT INITIAL AND ls_rfcsysacl_data-llicense_nr = ls_rfcsysacl_data-tlicense_nr.
            ls_result-explicit_selftrust = 'Explicit selftrust'.
          ELSE.
            ls_result-explicit_selftrust = 'explicit selftrust'. " no check for installation number
          ENDIF.
        ENDIF.
      ENDLOOP.

      " Store trusted systems
      APPEND ls_trusted_system TO lt_trusted_systems.

      " Store result
      IF tabix > 0.
        MODIFY lt_result FROM ls_result INDEX tabix.
      ELSE.
        APPEND ls_result TO lt_result.
      ENDIF.

    ENDLOOP. " lt_STORE_DIR

  ENDMETHOD. " get_RFCSYSACL

  METHOD get_rfcdes.
    CHECK p_dest = 'X'.

    DATA:
      lt_store_dir_tech TYPE  tt_diagst_store_dir_tech,
      lt_store_dir      TYPE  tt_diagst_store_dir,
      lt_fieldlist      TYPE  tt_diagst_table_store_fields,
      lt_snapshot       TYPE  tt_diagst_trows,
      rc                TYPE  i,
      rc_text           TYPE  natxt.

    DATA: tabix TYPE i.

    CALL FUNCTION 'DIAGST_GET_STORES'
      EXPORTING
        " The �System Filter� parameters allow to get all Stores of a system or technical system.
        " Some combinations of the four parameters are not allowed.
        " The function will return an error code in such a case.
*       SID                   = ' '
*       INSTALL_NUMBER        = ' '
*       LONG_SID              = ' '
*       TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)
        " Store key fields
        group_namespace       = 'ACTIVE'                   "(optional)
        group_landscape_class = 'CL_DIAGLS_ABAP_TECH_SYST' "(optional)
*       GROUP_LANDSCAPE_ID    = ' '
*       GROUP_COMP_ID         = ' '
        group_source          = 'ABAP'                     "(optional)
        group_name            = 'RFC-DESTINATIONS'         "(optional)
        store_category        = 'CONFIG'                   "(optional)
        store_type            = 'TABLE'                    "(optional)
*       STORE_FULLPATH        = ' '
        store_name            = 'RFCDES'
        " Special filters
        store_mainalias       = 'RFC-DESTINATIONS'         "(optional)
        store_subalias        = 'RFCDES'                   "(optional)
*       STORE_TPL_ID          = ' '
*       HAS_ELEMENT_FROM      =                            " date range
*       HAS_ELEMENT_TO        =                            " date range
*       ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*       CASE_INSENSITIVE      = ' '
*       PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*       SEARCH_STRING         =
*       ONLY_RELEVANT         = 'X'
*       PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll
        " Others
*       DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
        " Setting this parameter to �X� will display the result.
*       CALLING_APPL          = ' '
      IMPORTING
*       STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
        store_dir             = lt_store_dir               "(not recommended anymore)
*       STORE_DIR_MI          =                            "(SAP internal usage only)
*       STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*       PARAMETER             =                            "(SAP internal usage only)
        rc                    = rc
        rc_text               = rc_text.

    IF rc IS NOT INITIAL.
      MESSAGE e001(00) WITH rc_text.
    ENDIF.

    LOOP AT lt_store_dir INTO DATA(ls_store_dir)
      WHERE long_sid              IN p_sid
        AND store_main_state_type IN p_state
        .

      " Do we already have an entry for this system?
      READ TABLE lt_result INTO ls_result
        WITH KEY
          install_number = ls_store_dir-install_number
          long_sid       = ls_store_dir-long_sid
          sid            = ls_store_dir-sid
          .
      IF sy-subrc = 0.
        tabix = sy-tabix.
      ELSE.
        tabix = -1.
        CLEAR ls_result.
        MOVE-CORRESPONDING ls_store_dir TO ls_result.
      ENDIF.

      " Store destination data
      CLEAR ls_destination.
      ls_destination-sid            = ls_store_dir-sid.
      ls_destination-install_number = ls_store_dir-install_number.

      CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
        EXPORTING
          store_id  = ls_store_dir-store_id
*         TIMESTAMP =                        " if not specified the latest available snapshot is returned
*         CALLING_APPL                = ' '
        IMPORTING
          fieldlist = lt_fieldlist
*         SNAPSHOT_VALID_FROM         =
*         SNAPSHOT_VALID_TO_CONFIRMED =
*         SNAPSHOT_VALID_TO           =
          snapshot  = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*         SNAPSHOT_TR                 =
*         SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
          rc        = rc                     " 3: Permission denied, Content Authorization missing
          " 4: Store not existing
          " 8: Error
          rc_text   = rc_text.

      LOOP AT lt_snapshot INTO DATA(lt_snapshot_elem).
        READ TABLE lt_snapshot_elem INTO DATA(ls_rfcdest)       INDEX 1.
        CHECK ls_rfcdest-fieldname = 'RFCDEST'.

        READ TABLE lt_snapshot_elem INTO DATA(ls_rfctype)       INDEX 2.
        CHECK ls_rfctype-fieldname = 'RFCTYPE'.
        CHECK ls_rfctype-fieldvalue = '3' OR  ls_rfctype-fieldvalue = 'H' OR ls_rfctype-fieldvalue =  'W'.

        READ TABLE lt_snapshot_elem INTO DATA(ls_rfcoptions)    INDEX 3.
        CHECK ls_rfcoptions-fieldname = 'RFCOPTIONS'.

        " Store destination data
        DATA ls_destination_data TYPE ts_destination_data.
        CLEAR ls_destination_data.
        ls_destination_data-rfcdest = ls_rfcdest-fieldvalue.
        ls_destination_data-rfctype = ls_rfctype-fieldvalue.

        FIND REGEX ',\[=([^,]{3}),'    IN ls_rfcoptions-fieldvalue     " System ID
          SUBMATCHES ls_destination_data-sysid.

        FIND REGEX ',\^=([^,]{1,10}),' IN ls_rfcoptions-fieldvalue     " Installation number
          SUBMATCHES ls_destination_data-instnr.

        FIND REGEX ',Q=(Y),' IN ls_rfcoptions-fieldvalue               " Trusted
          SUBMATCHES ls_destination_data-trusted.

        FIND REGEX ',s=(Y),' IN ls_rfcoptions-fieldvalue               " SNC/TLS
          SUBMATCHES ls_destination_data-encrypted.

        append ls_destination_data to ls_destination-destination_data.

        " Update count
        CASE ls_destination_data-rfctype.

          WHEN '3'. " RFC destinations
            p_dest_3 = 'X'.
            ADD 1 TO ls_result-dest_3_cnt_all.                         " All destinations

            IF ls_destination_data-trusted is not initial.             " Trusted destination
              ADD 1 TO ls_result-dest_3_cnt_trusted.

              IF ls_destination_data-sysid is not initial.
                IF ls_destination_data-instnr is not initial.
                  " System ID and installation number are available
                  ADD 1 TO ls_result-dest_3_cnt_trusted_migrated.
                ELSE.
                  " Installation number is missing
                  ADD 1 TO ls_result-dest_3_cnt_trusted_no_instnr.
                ENDIF.
              ELSE.
                " System ID is missing
                ADD 1 TO ls_result-dest_3_cnt_trusted_no_sysid.
              ENDIF.

              IF ls_destination_data-encrypted is not initial.
                ADD 1 TO ls_result-dest_3_cnt_trusted_snc.
              ENDIF.
            ENDIF.

          WHEN 'H'. " http destinations
            p_dest_h = 'X'.
            ADD 1 TO ls_result-dest_h_cnt_all.                             " All destinations

            IF ls_destination_data-trusted is not initial.             " Trusted destination
              ADD 1 TO ls_result-dest_h_cnt_trusted.

              IF ls_destination_data-sysid is not initial.
                IF ls_destination_data-instnr is not initial.
                  " System ID and installation number are available
                  ADD 1 TO ls_result-dest_h_cnt_trusted_migrated.
                ELSE.
                  " Installation number is missing
                  ADD 1 TO ls_result-dest_h_cnt_trusted_no_instnr.
                ENDIF.
              ELSE.
                " System ID is missing
                ADD 1 TO ls_result-dest_h_cnt_trusted_no_sysid.
              ENDIF.

              IF ls_destination_data-encrypted is not initial.
                ADD 1 TO ls_result-dest_h_cnt_trusted_tls.
              ENDIF.
            ENDIF.

          WHEN 'W'. " web RFC destinations
            p_dest_w = 'X'.
            ADD 1 TO ls_result-dest_w_cnt_all.                             " All destinations

            IF ls_destination_data-trusted is not initial.             " Trusted destination
              ADD 1 TO ls_result-dest_w_cnt_trusted.

              IF ls_destination_data-sysid is not initial.
                IF ls_destination_data-instnr is not initial.
                  " System ID and installation number are available
                  ADD 1 TO ls_result-dest_w_cnt_trusted_migrated.
                ELSE.
                  " Installation number is missing
                  ADD 1 TO ls_result-dest_w_cnt_trusted_no_instnr.
                ENDIF.
              ELSE.
                " System ID is missing
                ADD 1 TO ls_result-dest_w_cnt_trusted_no_sysid.
              ENDIF.

              IF ls_destination_data-encrypted is not initial.
                ADD 1 TO ls_result-dest_w_cnt_trusted_tls.
              ENDIF.
            ENDIF.

        ENDCASE.

      ENDLOOP.

      IF tabix > 0.
        MODIFY lt_result FROM ls_result INDEX tabix.
      ELSE.
        APPEND ls_result TO lt_result.
      ENDIF.

      " Store destination data
      append ls_destination to lt_destinations.

    ENDLOOP. " lt_STORE_DIR

  ENDMETHOD. " get_RFCDES

  METHOD get_abap_instance_pahi.
    CHECK p_trust = 'X' OR p_dest = 'X'.

    " Same as in report ZSHOW_KERNEL_STORES but one one entry per system

    DATA:
      lt_store_dir_tech TYPE  tt_diagst_store_dir_tech,
      lt_store_dir      TYPE  tt_diagst_store_dir,
      lt_fieldlist      TYPE  tt_diagst_table_store_fields,
      lt_snapshot       TYPE  tt_diagst_trows,
      rc                TYPE  i,
      rc_text           TYPE  natxt.

    DATA: tabix TYPE i.

    CALL FUNCTION 'DIAGST_GET_STORES'
      EXPORTING
        " The �System Filter� parameters allow to get all Stores of a system or technical system.
        " Some combinations of the four parameters are not allowed.
        " The function will return an error code in such a case.
*       SID                   = ' '
*       INSTALL_NUMBER        = ' '
*       LONG_SID              = ' '
*       TECH_SYSTEM_TYPE      = 'ABAP'                     "(only together with LONG_SID)
        " Store key fields
        group_namespace       = 'ACTIVE'                   "(optional)
        group_landscape_class = 'CL_DIAGLS_ABAP_INSTANCE'  "(optional)
*       GROUP_LANDSCAPE_ID    = ' '
*       GROUP_COMP_ID         = ' '
        group_source          = 'ABAP'                     "(optional)
        group_name            = 'INSTANCE'                 "(optional)
        store_category        = 'CONFIG'                   "(optional)
        store_type            = 'PROPERTY'                 "(optional)
*       STORE_FULLPATH        = ' '
        store_name            = 'ABAP_INSTANCE_PAHI'
        " Special filters
        store_mainalias       = 'ABAP-PARAMETER'           "(optional)
        store_subalias        = 'PAHI'                     "(optional)
*       STORE_TPL_ID          = ' '
*       HAS_ELEMENT_FROM      =                            " date range
*       HAS_ELEMENT_TO        =                            " date range
*       ELEMENT_FILTER        = 'C'                        " (C)hange, (I)nitial, (A)ll
*       CASE_INSENSITIVE      = ' '
*       PATTERN_SEARCH        = 'X'                        " Allow pattern search for SEARCH_STRING
*       SEARCH_STRING         =
*       ONLY_RELEVANT         = 'X'
*       PROTECTED             = 'A'                        " (N)ot, (Y)es, (A)ll
        " Others
*       DISPLAY               = ' '                        " Only useful if the function is manually executed by transaction SE37.
        " Setting this parameter to �X� will display the result.
*       CALLING_APPL          = ' '
      IMPORTING
*       STORE_DIR_TECH        = lt_STORE_DIR_TECH          "(efficient, reduced structure)
        store_dir             = lt_store_dir               "(not recommended anymore)
*       STORE_DIR_MI          =                            "(SAP internal usage only)
*       STORE_STATS           =                            " History regarding the changes of elements (configuration items).
*       PARAMETER             =                            "(SAP internal usage only)
        rc                    = rc
        rc_text               = rc_text.

    IF rc IS NOT INITIAL.
      MESSAGE e001(00) WITH rc_text.
    ENDIF.

    LOOP AT lt_store_dir INTO DATA(ls_store_dir)
      WHERE long_sid              IN p_sid
        AND store_main_state_type IN p_state
      .

      " Do we already have an entry for this system?
      READ TABLE lt_result INTO ls_result
        WITH KEY
          install_number = ls_store_dir-install_number
          long_sid       = ls_store_dir-long_sid
          sid            = ls_store_dir-sid
          .
      IF sy-subrc = 0.
        tabix = sy-tabix.
        IF ls_store_dir-instance_type NE 'CENTRAL'.
          CONTINUE.
        ENDIF.
      ELSE.
        tabix = -1.
        CLEAR ls_result.
        MOVE-CORRESPONDING ls_store_dir TO ls_result.
      ENDIF.

      IF ls_result-host_full IS INITIAL.
        ls_result-host_full = ls_result-host. " host, host_id, physical_host
      ENDIF.

      CALL FUNCTION 'DIAGST_TABLE_SNAPSHOT'
        EXPORTING
          store_id  = ls_store_dir-store_id
*         TIMESTAMP =                        " if not specified the latest available snapshot is returned
*         CALLING_APPL                = ' '
        IMPORTING
          fieldlist = lt_fieldlist
*         SNAPSHOT_VALID_FROM         =
*         SNAPSHOT_VALID_TO_CONFIRMED =
*         SNAPSHOT_VALID_TO           =
          snapshot  = lt_snapshot            " The content of the requested snapshot in ABAP DDIC type format
*         SNAPSHOT_TR                 =
*         SNAPSHOT_ITSAM              =                        " The content of the requested snapshot in XML-based format
          rc        = rc                     " 3: Permission denied, Content Authorization missing
          " 4: Store not existing
          " 8: Error
          rc_text   = rc_text.

      LOOP AT lt_snapshot INTO DATA(lt_snapshot_elem).
        READ TABLE lt_snapshot_elem INTO DATA(ls_parameter) INDEX 1.
        CHECK ls_parameter-fieldname = 'PARAMETER'.

        READ TABLE lt_snapshot_elem INTO DATA(ls_value)     INDEX 2.
        CHECK ls_value-fieldname = 'VALUE'.

        CASE ls_parameter-fieldvalue.
          WHEN 'rfc/selftrust'.         ls_result-rfc_selftrust         = ls_value-fieldvalue.
          WHEN 'rfc/allowoldticket4tt'. ls_result-rfc_allowoldticket4tt = ls_value-fieldvalue.
          WHEN 'rfc/sendInstNr4tt'.     ls_result-rfc_sendinstnr4tt     = ls_value-fieldvalue.
        ENDCASE.
      ENDLOOP.

      IF tabix > 0.
        MODIFY lt_result FROM ls_result INDEX tabix.
      ELSE.
        APPEND ls_result TO lt_result.
      ENDIF.

    ENDLOOP. " lt_STORE_DIR

  ENDMETHOD. " get_ABAP_INSTANCE_PAHI

  METHOD validate_kernel.
    CHECK p_kern = 'X'.

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

    DATA:
      rel   TYPE i,
      patch TYPE i.

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_result>).

      IF <fs_result>-kern_rel IS INITIAL OR <fs_result>-kern_patchlevel IS INITIAL.
        <fs_result>-validate_kernel = 'Unknown Kernel'.
        APPEND VALUE #( fname = 'VALIDATE_KERNEL' color-col = col_normal ) TO <fs_result>-t_color.

      ELSE.
        rel   = <fs_result>-kern_rel(3).
        patch = <fs_result>-kern_patchlevel.

        IF     rel = 722 AND patch < 1214
          OR   rel = 753 AND patch < 1036
          OR   rel = 754 AND patch < 18
          OR   rel = 777 AND patch < 516
          OR   rel = 781 AND patch < 300
          OR   rel = 785 AND patch < 214
          OR   rel = 788 AND patch < 21
          OR   rel = 789 AND patch < 10
          .
          <fs_result>-validate_kernel = 'Kernel patch required'.
          APPEND VALUE #( fname = 'VALIDATE_KERNEL' color-col = col_total ) TO <fs_result>-t_color.

        ELSEIF rel < 722
            OR rel > 722 AND rel < 753
            .
          <fs_result>-validate_kernel = `Release update required`.
          APPEND VALUE #( fname = 'VALIDATE_KERNEL' color-col = col_negative ) TO <fs_result>-t_color.

        ELSE.

          <fs_result>-validate_kernel = 'ok'.
          APPEND VALUE #( fname = 'VALIDATE_KERNEL' color-col = col_positive ) TO <fs_result>-t_color.

        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD. " validate_kernel

  METHOD validate_abap.
    CHECK p_abap = 'X' OR p_trust = 'X' OR p_dest = 'X'.

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

    DATA:
      rel TYPE i,
      sp  TYPE i.

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<fs_result>).

      " Validate release and SP
      IF <fs_result>-abap_release IS INITIAL OR <fs_result>-abap_sp IS INITIAL.
        <fs_result>-validate_abap = 'Unknown ABAP version'.
        APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_normal ) TO <fs_result>-t_color.

      ELSE.
        rel   = <fs_result>-abap_release.
        sp    = <fs_result>-abap_sp.

        IF     rel < 700
          OR   rel = 700 AND sp < 35
          OR   rel = 701 AND sp < 20
          OR   rel = 702 AND sp < 20
          OR   rel = 731 AND sp < 19
          OR   rel = 740 AND sp < 16
          OR   rel = 750 AND sp < 12
          OR   rel = 751 AND sp < 7
          OR   rel = 752 AND sp < 1
          .
          <fs_result>-validate_abap = 'ABAP SP required'.
          APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_negative ) TO <fs_result>-t_color.

        ELSEIF rel = 700 AND sp < 41
          OR   rel = 701 AND sp < 26
          OR   rel = 702 AND sp < 26
          OR   rel = 731 AND sp < 33
          OR   rel = 740 AND sp < 30
          OR   rel = 750 AND sp < 26
          OR   rel = 751 AND sp < 16
          OR   rel = 752 AND sp < 12
          OR   rel = 753 AND sp < 10
          OR   rel = 754 AND sp < 8
          OR   rel = 755 AND sp < 6
          OR   rel = 756 AND sp < 4
          OR   rel = 757 AND sp < 2
          OR   rel > 757
          .
          <fs_result>-validate_abap = 'Note required'.
          APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_total ) TO <fs_result>-t_color.

          IF <fs_result>-note_3089413 IS INITIAL.
            <fs_result>-note_3089413 = 'required'.
          ENDIF.
          IF <fs_result>-note_3287611 IS INITIAL.
            <fs_result>-note_3287611 = 'required'.
          ENDIF.

        ELSEIF rel = 750 AND sp < 27
          OR   rel = 751 AND sp < 17
          .
          <fs_result>-validate_abap = 'Note required'.
          APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_total ) TO <fs_result>-t_color.

          IF <fs_result>-note_3089413 IS INITIAL.
            <fs_result>-note_3089413 = 'ok'.
          ENDIF.
          IF <fs_result>-note_3287611 IS INITIAL.
            <fs_result>-note_3287611 = 'required'.
          ENDIF.

        ELSE.
          <fs_result>-validate_abap = 'ok'.
          APPEND VALUE #( fname = 'VALIDATE_ABAP' color-col = col_positive ) TO <fs_result>-t_color.

          IF <fs_result>-note_3089413 IS INITIAL.
            <fs_result>-note_3089413 = 'ok'.
          ENDIF.
          IF <fs_result>-note_3287611 IS INITIAL.
            <fs_result>-note_3287611 = 'ok'.
          ENDIF.

        ENDIF.
      ENDIF.

      " Validate notes
      "   Undefined Implementation State
      " -	Cannot be implemented
      " E	Completely implemented
      " N	Can be implemented
      " O	Obsolete
      " U	Incompletely implemented
      " V	Obsolete version implemented
      CASE <fs_result>-note_3089413_prstatus.
        WHEN 'E' OR '-'.
          APPEND VALUE #( fname = 'NOTE_3089413' color-col = col_positive ) TO <fs_result>-t_color.
        WHEN 'N' OR 'O' OR 'U' OR 'V'.
          APPEND VALUE #( fname = 'NOTE_3089413' color-col = col_negative ) TO <fs_result>-t_color.
        WHEN OTHERS.
          IF     <fs_result>-note_3089413 = 'ok'.
            APPEND VALUE #( fname = 'NOTE_3089413' color-col = col_positive ) TO <fs_result>-t_color.
          ELSEIF <fs_result>-note_3089413 = 'required'.
            APPEND VALUE #( fname = 'NOTE_3089413' color-col = col_negative ) TO <fs_result>-t_color.
          ENDIF.
      ENDCASE.
      CASE <fs_result>-note_3287611_prstatus.
        WHEN 'E' OR '-'.
          APPEND VALUE #( fname = 'NOTE_3287611' color-col = col_positive ) TO <fs_result>-t_color.
        WHEN 'N' OR 'O' OR 'U' OR 'V'.
          APPEND VALUE #( fname = 'NOTE_3287611' color-col = col_negative ) TO <fs_result>-t_color.
        WHEN OTHERS.
          IF     <fs_result>-note_3287611 = 'ok'.
            APPEND VALUE #( fname = 'NOTE_3287611' color-col = col_positive ) TO <fs_result>-t_color.
          ELSEIF <fs_result>-note_3287611 = 'required'.
            APPEND VALUE #( fname = 'NOTE_3287611' color-col = col_negative ) TO <fs_result>-t_color.
          ENDIF.
      ENDCASE.

      " Validate trusted systems
      IF <fs_result>-trustsy_cnt_3 > 0.
        APPEND VALUE #( fname = 'TRUSTSY_CNT_3' color-col = col_positive ) TO <fs_result>-t_color.
      ENDIF.
      IF <fs_result>-trustsy_cnt_2 > 0.
        APPEND VALUE #( fname = 'TRUSTSY_CNT_2' color-col = col_negative ) TO <fs_result>-t_color.
      ENDIF.
      IF <fs_result>-trustsy_cnt_1 > 0.
        APPEND VALUE #( fname = 'TRUSTSY_CNT_1' color-col = col_negative ) TO <fs_result>-t_color.
      ENDIF.

      " Validate TCD flag
      IF <fs_result>-trustsy_cnt_tcd > 0.
        APPEND VALUE #( fname = 'TRUSTSY_CNT_TCD' color-col = col_positive ) TO <fs_result>-t_color.
      ENDIF.

      " Validate rfc/selftrust
      IF <fs_result>-rfc_selftrust = '0'.
        APPEND VALUE #( fname = 'RFC_SELFTRUST' color-col = col_positive ) TO <fs_result>-t_color.
      ELSEIF <fs_result>-rfc_selftrust = '1'.
        APPEND VALUE #( fname = 'RFC_SELFTRUST' color-col = col_total ) TO <fs_result>-t_color.
      ENDIF.

      " Validate trusted destinations
      IF <fs_result>-dest_3_cnt_trusted_migrated > 0.
        APPEND VALUE #( fname = 'DEST_3_CNT_TRUSTED_MIGRATED' color-col = col_positive ) TO <fs_result>-t_color.
      ENDIF.
      IF <fs_result>-dest_3_cnt_trusted_no_instnr > 0.
        APPEND VALUE #( fname = 'DEST_3_CNT_TRUSTED_NO_INSTNR' color-col = col_negative ) TO <fs_result>-t_color.
      ENDIF.
      IF <fs_result>-dest_3_cnt_trusted_no_sysid > 0.
        APPEND VALUE #( fname = 'DEST_3_CNT_TRUSTED_NO_SYSID' color-col = col_negative ) TO <fs_result>-t_color.
      ENDIF.

      IF <fs_result>-dest_h_cnt_trusted_migrated > 0.
        APPEND VALUE #( fname = 'DEST_H_CNT_TRUSTED_MIGRATED' color-col = col_positive ) TO <fs_result>-t_color.
      ENDIF.
      IF <fs_result>-dest_h_cnt_trusted_no_instnr > 0.
        APPEND VALUE #( fname = 'DEST_H_CNT_TRUSTED_NO_INSTNR' color-col = col_negative ) TO <fs_result>-t_color.
      ENDIF.
      IF <fs_result>-dest_h_cnt_trusted_no_sysid > 0.
        APPEND VALUE #( fname = 'DEST_H_CNT_TRUSTED_NO_SYSID' color-col = col_negative ) TO <fs_result>-t_color.
      ENDIF.

      IF <fs_result>-dest_w_cnt_trusted_migrated > 0.
        APPEND VALUE #( fname = 'DEST_W_CNT_TRUSTED_MIGRATED' color-col = col_positive ) TO <fs_result>-t_color.
      ENDIF.
      IF <fs_result>-dest_w_cnt_trusted_no_instnr > 0.
        APPEND VALUE #( fname = 'DEST_W_CNT_TRUSTED_NO_INSTNR' color-col = col_negative ) TO <fs_result>-t_color.
      ENDIF.
      IF <fs_result>-dest_w_cnt_trusted_no_sysid > 0.
        APPEND VALUE #( fname = 'DEST_3_CNT_TRUSTED_NO_SYSID' color-col = col_negative ) TO <fs_result>-t_color.
      ENDIF.

    ENDLOOP.
  ENDMETHOD. " validate_ABAP

  METHOD validate_mutual_trust.
    CHECK p_trust = 'X'.

    FIELD-SYMBOLS:
      <fs_trusted_system>   TYPE ts_trusted_system,
      <fs_rfcsysacl_data>   TYPE ts_rfcsysacl_data,
      <fs_trusted_system_2> TYPE ts_trusted_system,
      <fs_rfcsysacl_data_2> TYPE ts_rfcsysacl_data,
      <fs_result>           TYPE ts_result.

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
    LOOP AT lt_trusted_systems ASSIGNING <fs_trusted_system>.

      " Get trusted systems
      LOOP AT <fs_trusted_system>-rfcsysacl_data ASSIGNING <fs_rfcsysacl_data>
        WHERE rfcsysid    NE <fs_trusted_system>-rfctrustsy   " Ignore selftrust
           "or TLICENSE_NR ne <fs_TRUSTED_SYSTEM>-LLICENSE_NR
           .

        LOOP AT lt_trusted_systems ASSIGNING <fs_trusted_system_2>
          WHERE rfctrustsy  = <fs_rfcsysacl_data>-rfcsysid
            "and LLICENSE_NR = <fs_RFCSYSACL_data>-TLICENSE_NR
            .

          LOOP AT <fs_trusted_system_2>-rfcsysacl_data ASSIGNING <fs_rfcsysacl_data_2>
            WHERE rfcsysid     = <fs_rfcsysacl_data>-rfctrustsy
              "and TLICENSE_NR  = <fs_RFCSYSACL_data>-LLICENSE_NR
              .

            " Store mutual trust
            READ TABLE lt_result ASSIGNING <fs_result>
              WITH KEY
                install_number = <fs_rfcsysacl_data>-llicense_nr
                "long_sid       =
                sid            = <fs_rfcsysacl_data>-rfctrustsy
                .
            IF sy-subrc = 0.
              ADD 1 TO <fs_result>-mutual_trust_cnt.
              IF <fs_result>-mutual_trust_cnt = 1.
                APPEND VALUE #( fname = 'MUTUAL_TRUST_CNT' color-col = col_total ) TO <fs_result>-t_color.
              ENDIF.
            ENDIF.

            <fs_rfcsysacl_data>-mutual_trust   = 'mutual'.
            <fs_rfcsysacl_data_2>-mutual_trust = 'mutual'.

            "write: /(3) <fs_RFCSYSACL_data>-RFCSYSID,     <fs_RFCSYSACL_data>-TLICENSE_NR,   (3) <fs_RFCSYSACL_data>-RFCTRUSTSY,   <fs_RFCSYSACL_data>-LLICENSE_NR.   " <fs_RFCSYSACL_data>
            "write:  (3) <fs_RFCSYSACL_data_2>-RFCTRUSTSY, <fs_RFCSYSACL_data_2>-LLICENSE_NR, (3) <fs_RFCSYSACL_data_2>-RFCSYSID,   <fs_RFCSYSACL_data_2>-TLICENSE_NR. " <fs_RFCSYSACL_data_2>

          ENDLOOP.
        ENDLOOP.

        IF sy-subrc IS NOT INITIAL                      " No data of trusted system found?
          AND <fs_rfcsysacl_data>-rfcsysid IN p_sid.    " But check this only of data should be available

          " Store mutual trust
          READ TABLE lt_result ASSIGNING <fs_result>
            WITH KEY
              install_number = <fs_rfcsysacl_data>-llicense_nr
              "long_sid       =
              sid            = <fs_rfcsysacl_data>-rfctrustsy
              .
          IF sy-subrc = 0.
            ADD 1 TO <fs_result>-no_data_cnt.
            IF <fs_result>-mutual_trust_cnt = 1.
              APPEND VALUE #( fname = 'MUTUAL_TRUST_CNT' color-col = col_total ) TO <fs_result>-t_color.
            ENDIF.
          ENDIF.

          <fs_rfcsysacl_data>-no_data = 'no data'.

        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD. " validate_mutual_trust

  METHOD on_user_command.
*    importing e_salv_function

    " Get selected item(s)
    DATA(lr_selections)   = lr_alv_table->get_selections( ).
    DATA(ls_cell)         = lr_selections->get_current_cell( ).
    DATA(lt_seleced_rows) = lr_selections->get_selected_rows( ).

    CASE e_salv_function.

      WHEN 'PICK'. " Double click

        IF ls_cell-row > 0.
          READ TABLE lt_result INTO DATA(ls_result) INDEX ls_cell-row.
          CHECK sy-subrc = 0.

          " Show trusted systems
          IF   ls_cell-columnname(12) = 'TRUSTSY_CNT_'
            OR ls_cell-columnname = 'MUTUAL_TRUST_CNT'
            OR ls_cell-columnname = 'NO_DATA_CNT'.

            show_trusted_systems(
              column      = ls_cell-columnname
              llicense_nr = ls_result-install_number
              rfctrustsy  = ls_result-sid
            ).

          " Show destinations
          ELSEIF ls_cell-columnname(11) = 'DEST_3_CNT_'
            OR ls_cell-columnname(11) = 'DEST_H_CNT_'
            OR ls_cell-columnname(11) = 'DEST_W_CNT_'.

            show_destinations(
              column      = ls_cell-columnname
              install_number = ls_result-install_number
              sid  = ls_result-sid
            ).

          ENDIF.
        ENDIF.
    ENDCASE.

  ENDMETHOD. " on_user_command

  METHOD on_double_click.
*   importing row column

    " Get selected item(s)
    DATA(lr_selections) = lr_alv_table->get_selections( ).
    DATA(ls_cell) = lr_selections->get_current_cell( ).
    DATA(lt_seleced_rows) = lr_selections->get_selected_rows( ).

    IF row > 0.
      READ TABLE lt_result INTO DATA(ls_result) INDEX row.
      CHECK sy-subrc = 0.

      " Show trusted systems
      IF   column(12) = 'TRUSTSY_CNT_'
        OR column = 'MUTUAL_TRUST_CNT'
        OR column = 'NO_DATA_CNT'.

        show_trusted_systems(
          column      = column
          llicense_nr = ls_result-install_number
          rfctrustsy  = ls_result-sid
        ).

      " Show destinations
      ELSEIF column(11) = 'DEST_3_CNT_'
        OR column(11) = 'DEST_H_CNT_'
        OR column(11) = 'DEST_W_CNT_'.

        show_destinations(
          column      = column
          install_number = ls_result-install_number
          sid  = ls_result-sid
        ).

      ENDIF.
    ENDIF.

  ENDMETHOD. " on_double_click

  METHOD show_result.
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
            r_salv_table = lr_alv_table
          CHANGING
            t_table      = lt_result ).
      CATCH cx_salv_msg.
    ENDTRY.

*... activate ALV generic Functions
    lr_functions = lr_alv_table->get_functions( ).
    lr_functions->set_all( abap_true ).

*... set the display settings
    lr_display = lr_alv_table->get_display_settings( ).
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
    lr_functional = lr_alv_table->get_functional_settings( ).
    TRY.
        lr_functional->set_sort_on_header_click( abap_true ).
        "lr_functional->set_f2_code( f2code ).
        "lr_functional->set_buffer( gs_test-settings-functional-buffer ).
      CATCH cx_salv_method_not_supported.
    ENDTRY.

* ...Set the layout
    lr_layout = lr_alv_table->get_layout( ).
    ls_layout_key-report = sy-repid.
    lr_layout->set_key( ls_layout_key ).
    lr_layout->set_initial_layout( p_layout ).
    AUTHORITY-CHECK OBJECT 'S_ALV_LAYO'
                        ID 'ACTVT' FIELD '23'.
    IF sy-subrc = 0.
      lr_layout->set_save_restriction( cl_salv_layout=>restrict_none ) . "no restictions
    ELSE.
      lr_layout->set_save_restriction( cl_salv_layout=>restrict_user_dependant ) . "user dependend
    ENDIF.

*... sort
    TRY.
        lr_sorts = lr_alv_table->get_sorts( ).
        lr_sorts->add_sort( 'INSTALL_NUMBER' ).
        lr_sorts->add_sort( 'LONG_SID' ).
        lr_sorts->add_sort( 'SID' ).

      CATCH cx_salv_data_error cx_salv_existing cx_salv_not_found.
    ENDTRY.

*... set column appearance
    lr_columns = lr_alv_table->get_columns( ).
    lr_columns->set_optimize( abap_true ). " Optimize column width

*... set the color of cells
    TRY.
        lr_columns->set_color_column( 'T_COLOR' ).
      CATCH cx_salv_data_error.                         "#EC NO_HANDLER
    ENDTRY.

* register to the events of cl_salv_table
    lr_events = lr_alv_table->get_event( ).
    CREATE OBJECT lr_alv_events.
* register to the event USER_COMMAND
    SET HANDLER lr_alv_events->on_user_command FOR lr_events.
* register to the event DOUBLE_CLICK
    SET HANDLER lr_alv_events->on_double_click FOR lr_events.

* set selection mode
    lr_selections = lr_alv_table->get_selections( ).
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

        IF p_kern IS INITIAL.
          lr_column ?= lr_columns->get_column( 'KERN_REL' ).              lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'KERN_PATCHLEVEL' ).       lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'KERN_COMP_TIME' ).        lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'KERN_COMP_DATE' ).        lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'VALIDATE_KERNEL' ).       lr_column->set_technical( abap_true ).
        ENDIF.

        IF p_abap IS INITIAL.
          lr_column ?= lr_columns->get_column( 'ABAP_RELEASE' ).          lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'ABAP_SP' ).               lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'VALIDATE_ABAP' ).         lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'NOTE_3089413' ).          lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'NOTE_3089413_PRSTATUS' ). lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'NOTE_3287611' ).          lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'NOTE_3287611_PRSTATUS' ). lr_column->set_technical( abap_true ).
        ENDIF.

        IF p_trust IS INITIAL.
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
        ENDIF.

        IF p_dest IS INITIAL OR p_dest_3 IS INITIAL.
          lr_column ?= lr_columns->get_column( 'DEST_3_CNT_ALL' ).               lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED' ).           lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_MIGRATED' ).  lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_NO_INSTNR' ). lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_NO_SYSID' ).  lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_3_CNT_TRUSTED_SNC' ).       lr_column->set_technical( abap_true ).
        ENDIF.

        IF p_dest IS INITIAL OR p_dest_h IS INITIAL.
          lr_column ?= lr_columns->get_column( 'DEST_H_CNT_ALL' ).               lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED' ).           lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_MIGRATED' ).  lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_NO_INSTNR' ). lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_NO_SYSID' ).  lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_H_CNT_TRUSTED_TLS' ).       lr_column->set_technical( abap_true ).
        ENDIF.

        IF p_dest IS INITIAL OR p_dest_w IS INITIAL.
          lr_column ?= lr_columns->get_column( 'DEST_W_CNT_ALL' ).               lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED' ).           lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_MIGRATED' ).  lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_NO_INSTNR' ). lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_NO_SYSID' ).  lr_column->set_technical( abap_true ).
          lr_column ?= lr_columns->get_column( 'DEST_W_CNT_TRUSTED_TLS' ).       lr_column->set_technical( abap_true ).
        ENDIF.

        IF p_trust IS INITIAL AND p_dest IS INITIAL.
          lr_column ?= lr_columns->get_column( 'RFC_ALLOWOLDTICKET4TT' ). lr_column->set_technical( abap_true ).
        ENDIF.

      CATCH cx_salv_not_found.
    ENDTRY.

*... show it
    lr_alv_table->display( ).

  ENDMETHOD. " show_result

  METHOD show_trusted_systems.
    "IMPORTING
    "  column      type SALV_DE_COLUMN
    "  LLICENSE_NR type ts_result-install_number
    "  RFCTRUSTSY  type ts_result-sid

    " Show trusted systems
    CHECK column(12) = 'TRUSTSY_CNT_'
       OR column = 'MUTUAL_TRUST_CNT'
       OR column = 'NO_DATA_CNT'.

    DATA: ls_trusted_system  TYPE ts_trusted_system.
    READ TABLE lt_trusted_systems ASSIGNING FIELD-SYMBOL(<fs_trusted_system>)
      WITH TABLE KEY
        rfctrustsy  = rfctrustsy
        llicense_nr = llicense_nr.
    CHECK sy-subrc = 0.

    DATA:
      ls_rfcsysacl_data TYPE ts_rfcsysacl_data,
      lt_rfcsysacl_data TYPE tt_rfcsysacl_data.

    " ALV
    DATA:
      lr_table TYPE REF TO cl_salv_table.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lr_table
          CHANGING
            t_table      = lt_rfcsysacl_data ).
      CATCH cx_salv_msg.
    ENDTRY.

*... activate ALV generic Functions
    DATA(lr_functions) = lr_table->get_functions( ).
    lr_functions->set_all( abap_true ).

*... set the display settings
    DATA(lr_display) = lr_table->get_display_settings( ).
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
    DATA(lr_functional) = lr_table->get_functional_settings( ).
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
    DATA(lr_columns) = lr_table->get_columns( ).
    lr_columns->set_optimize( abap_true ). " Optimize column width

*... set the color of cells
    TRY.
        lr_columns->set_color_column( 'T_COLOR' ).
      CATCH cx_salv_data_error.                         "#EC NO_HANDLER
    ENDTRY.

    " Copy relevant data
    CASE column.
      WHEN 'TRUSTSY_CNT_ALL'. " All trusted systems
        lr_display->set_list_header( `All trusted systems of system ` && rfctrustsy ).

        LOOP AT <fs_trusted_system>-rfcsysacl_data INTO ls_rfcsysacl_data.
          APPEND ls_rfcsysacl_data TO lt_rfcsysacl_data.
        ENDLOOP.

      WHEN 'NO_DATA_CNT'.   " No data for trusted system found
        lr_display->set_list_header( `No data for trusted system found of system ` && rfctrustsy ).

        LOOP AT <fs_trusted_system>-rfcsysacl_data INTO ls_rfcsysacl_data
          WHERE no_data IS NOT INITIAL.
          APPEND ls_rfcsysacl_data TO lt_rfcsysacl_data.
        ENDLOOP.

      WHEN 'MUTUAL_TRUST_CNT'.   " Mutual trust relations
        lr_display->set_list_header( `Mutual trust relations with system ` && rfctrustsy ).

        LOOP AT <fs_trusted_system>-rfcsysacl_data INTO ls_rfcsysacl_data
          WHERE mutual_trust IS NOT INITIAL.
          APPEND ls_rfcsysacl_data TO lt_rfcsysacl_data.
        ENDLOOP.

      WHEN 'TRUSTSY_CNT_TCD'. " Tcode active for trusted systems
        lr_display->set_list_header( `Tcode active for trusted systems of system ` && rfctrustsy ).

        LOOP AT <fs_trusted_system>-rfcsysacl_data INTO ls_rfcsysacl_data
          WHERE rfctcdchk = 'X'.
          APPEND ls_rfcsysacl_data TO lt_rfcsysacl_data.
        ENDLOOP.

      WHEN 'TRUSTSY_CNT_3'.   " Migrated trusted systems
        lr_display->set_list_header( `Migrated trusted systems of system ` && rfctrustsy ).

        LOOP AT <fs_trusted_system>-rfcsysacl_data INTO ls_rfcsysacl_data
          WHERE rfcslopt(1) = '3'.
          APPEND ls_rfcsysacl_data TO lt_rfcsysacl_data.
        ENDLOOP.

      WHEN 'TRUSTSY_CNT_2'.   " Old trusted systems
        lr_display->set_list_header( `Old trusted systems of system ` && rfctrustsy ).

        LOOP AT <fs_trusted_system>-rfcsysacl_data INTO ls_rfcsysacl_data
          WHERE rfcslopt(1) = '2'.
          APPEND ls_rfcsysacl_data TO lt_rfcsysacl_data.
        ENDLOOP.

      WHEN 'TRUSTSY_CNT_1'.   " Very old trusted systems
        lr_display->set_list_header( `Very old trusted systems of system ` && rfctrustsy ).

        LOOP AT <fs_trusted_system>-rfcsysacl_data INTO ls_rfcsysacl_data
          WHERE rfcslopt(1) = ' '.
          APPEND ls_rfcsysacl_data TO lt_rfcsysacl_data.
        ENDLOOP.

    ENDCASE.

    " Set color
    LOOP AT lt_rfcsysacl_data ASSIGNING FIELD-SYMBOL(<fs_rfcsysacl_data>).
      IF <fs_rfcsysacl_data>-mutual_trust IS NOT INITIAL.
        APPEND VALUE #( fname = 'MUTUAL_TRUST' color-col = col_total ) TO <fs_rfcsysacl_data>-t_color.
      ENDIF.

      IF <fs_rfcsysacl_data>-rfctcdchk IS NOT INITIAL.
        APPEND VALUE #( fname = 'RFCTCDCHK' color-col = col_positive ) TO <fs_rfcsysacl_data>-t_color.
      ENDIF.

      IF <fs_rfcsysacl_data>-rfcslopt(1) = '3'.
        APPEND VALUE #( fname = 'RFCSLOPT' color-col = col_positive ) TO <fs_rfcsysacl_data>-t_color.
      ELSE.
        APPEND VALUE #( fname = 'RFCSLOPT' color-col = col_negative ) TO <fs_rfcsysacl_data>-t_color.
      ENDIF.
    ENDLOOP.

    TRY.
        DATA lr_column TYPE REF TO cl_salv_column_table.        " Columns in Simple, Two-Dimensional Tables

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

  ENDMETHOD. " show_trusted_systems

  METHOD show_destinations.
    "IMPORTING
    "  column      TYPE salv_de_column
    "  install_number TYPE ts_result-install_number
    "  sid         TYPE ts_result-sid.

    " Show trusted systems
    CHECK column(11) = 'DEST_3_CNT_'
       OR column(11) = 'DEST_H_CNT_'
       OR column(11) = 'DEST_W_CNT_'.

    DATA: ls_destination  TYPE ts_destination.
    READ TABLE lt_destinations ASSIGNING FIELD-SYMBOL(<fs_destination>)
      WITH TABLE KEY
        sid            = sid
        install_number = install_number.
    CHECK sy-subrc = 0.

    DATA:
      ls_destination_data TYPE ts_destination_data,
      lt_destination_data TYPE tt_destination_data.

    " ALV
    DATA:
      lr_table TYPE REF TO cl_salv_table.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lr_table
          CHANGING
            t_table      = lt_destination_data ).
      CATCH cx_salv_msg.
    ENDTRY.

*... activate ALV generic Functions
    DATA(lr_functions) = lr_table->get_functions( ).
    lr_functions->set_all( abap_true ).

*... set the display settings
    DATA(lr_display) = lr_table->get_display_settings( ).
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
    DATA(lr_functional) = lr_table->get_functional_settings( ).
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
    DATA(lr_columns) = lr_table->get_columns( ).
    lr_columns->set_optimize( abap_true ). " Optimize column width

*... set the color of cells
    TRY.
        lr_columns->set_color_column( 'T_COLOR' ).
      CATCH cx_salv_data_error.                         "#EC NO_HANDLER
    ENDTRY.

    " Copy relevant data
    CASE column.
      WHEN 'DEST_3_CNT_ALL'.
        lr_display->set_list_header( `All RFC destinations (type 3) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = '3'.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_3_CNT_TRUSTED'.
        lr_display->set_list_header( `Trusted RFC destinations (type 3) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = '3'
            and trusted is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_3_CNT_TRUSTED_MIGRATED'.
        lr_display->set_list_header( `Migrated RFC destinations (type 3) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = '3'
            and trusted is not initial
            and sysid   is not initial
            and instnr  is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_3_CNT_TRUSTED_NO_INSTNR'.
        lr_display->set_list_header( `Missing installation number in RFC destinations (type 3) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = '3'
            and trusted is not initial
            and sysid   is not initial
            and instnr  is initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_3_CNT_TRUSTED_NO_SYSID'.
        lr_display->set_list_header( `Missing system id in RFC destinations (type 3) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = '3'
            and trusted is not initial
            and sysid   is initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_3_CNT_TRUSTED_SNC'.
        lr_display->set_list_header( `Encrypted trusted RFC destinations (type 3) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = '3'
            and trusted is not initial
            and encrypted is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.


      WHEN 'DEST_H_CNT_ALL'.
        lr_display->set_list_header( `All http destinations (type H) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'H'.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_H_CNT_TRUSTED'.
        lr_display->set_list_header( `Trusted http destinations (type H) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'H'
            and trusted is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_H_CNT_TRUSTED_MIGRATED'.
        lr_display->set_list_header( `Migrated http destinations (type H) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'H'
            and trusted is not initial
            and sysid   is not initial
            and instnr  is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_H_CNT_TRUSTED_NO_INSTNR'.
        lr_display->set_list_header( `Missing installation number in http destinations (type H) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'H'
            and trusted is not initial
            and sysid   is not initial
            and instnr  is initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_H_CNT_TRUSTED_NO_SYSID'.
        lr_display->set_list_header( `Missing system id in http destinations (type H) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'H'
            and trusted is not initial
            and sysid   is initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_H_CNT_TRUSTED_TLS'.
        lr_display->set_list_header( `Encrypted trusted http destinations (type H) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'H'
            and trusted is not initial
            and encrypted is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.


      WHEN 'DEST_W_CNT_ALL'.
        lr_display->set_list_header( `All WebRFC destinations (type W) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'W'.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_W_CNT_TRUSTED'.
        lr_display->set_list_header( `Trusted WebRFC destinations (type W) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'W'
            and trusted is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_W_CNT_TRUSTED_MIGRATED'.
        lr_display->set_list_header( `Migrated WebRFC destinations (type W) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'W'
            and trusted is not initial
            and sysid   is not initial
            and instnr  is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_W_CNT_TRUSTED_NO_INSTNR'.
        lr_display->set_list_header( `Missing installation number in WebRFC destinations (type W) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'W'
            and trusted is not initial
            and sysid   is not initial
            and instnr  is initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_W_CNT_TRUSTED_NO_SYSID'.
        lr_display->set_list_header( `Missing system id in WebRFC destinations (type W) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'W'
            and trusted is not initial
            and sysid   is initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

      WHEN 'DEST_W_CNT_TRUSTED_TLS'.
        lr_display->set_list_header( `Encrypted trusted WebRFC destinations (type W) of system ` && sid ).

        LOOP AT <fs_destination>-destination_data INTO ls_destination_data
          where rfctype = 'W'
            and trusted is not initial
            and encrypted is not initial.
          APPEND ls_destination_data TO lt_destination_data.
        ENDLOOP.

    ENDCASE.

    " Set color
    LOOP AT lt_destination_data ASSIGNING FIELD-SYMBOL(<fs_destination_data>)
      where trusted is not initial.

      IF <fs_destination_data>-sysid IS NOT INITIAL.
        APPEND VALUE #( fname = 'SYSID' color-col = col_positive ) TO <fs_destination_data>-t_color.
      ELSE.
        APPEND VALUE #( fname = 'SYSID' color-col = col_negative ) TO <fs_destination_data>-t_color.
      ENDIF.
      IF <fs_destination_data>-instnr IS NOT INITIAL.
        APPEND VALUE #( fname = 'INSTNR' color-col = col_positive ) TO <fs_destination_data>-t_color.
      ELSE.
        APPEND VALUE #( fname = 'INSTNR' color-col = col_negative ) TO <fs_destination_data>-t_color.
      ENDIF.
    ENDLOOP.

    TRY.
        DATA lr_column TYPE REF TO cl_salv_column_table.        " Columns in Simple, Two-Dimensional Tables

        lr_column ?= lr_columns->get_column( 'RFCDEST' ).
        lr_column->set_long_text( 'Destination' ).
        lr_column->set_medium_text( 'Destination' ).
        lr_column->set_short_text( 'Dest.').

        lr_column ?= lr_columns->get_column( 'RFCTYPE' ).

        lr_column ?= lr_columns->get_column( 'TRUSTED' ).
        lr_column->set_long_text( 'Trusted destination' ).
        lr_column->set_medium_text( 'Trusted dest.' ).
        lr_column->set_short_text( 'Trusted').

        lr_column ?= lr_columns->get_column( 'SYSID' ).
        lr_column->set_long_text( 'System ID' ).
        lr_column->set_medium_text( 'System ID' ).
        lr_column->set_short_text( 'System ID').

        lr_column ?= lr_columns->get_column( 'INSTNR' ).
        lr_column->set_long_text( 'Installation number' ).
        lr_column->set_medium_text( 'Installation nr' ).
        lr_column->set_short_text( 'Inst. nr').

        lr_column ?= lr_columns->get_column( 'ENCRYPTED' ).
        lr_column->set_long_text( 'Encrypted using SNC/TLS' ).
        lr_column->set_medium_text( 'Encrypted (SNC/TLS)' ).
        lr_column->set_short_text( 'Encrypted').

      CATCH cx_salv_not_found.
    ENDTRY.

    " Show it
    lr_table->display( ).

  ENDMETHOD. " show_destinations

ENDCLASS.                    "lcl_report IMPLEMENTATION

*----------------------------------------------------------------------*
*      REPORT events
*----------------------------------------------------------------------*
INITIALIZATION.
  lcl_report=>initialization( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sid-low.
  lcl_report=>f4_s_sid( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sid-high.
  lcl_report=>f4_s_sid( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_layout.
  lcl_report=>f4_p_layout( CHANGING layout = p_layout ).

AT SELECTION-SCREEN ON p_layout.
  CHECK NOT p_layout IS INITIAL.
  lcl_report=>at_selscr_on_p_layout( p_layout ).

START-OF-SELECTION.
  lcl_report=>start_of_selection( ).
