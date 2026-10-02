import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<String> _languages = ['en', 'ar'];

  bool get isArabic => locale.languageCode == 'ar';

  String get appTitle => _t('app_title');
  String get contacts => _t('contacts');
  String get groups => _t('groups');
  String get messaging => _t('messaging');
  String get history => _t('history');
  String get settings => _t('settings');
  String get search => _t('search');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get delete => _t('delete');
  String get confirm => _t('confirm');
  String get noData => _t('no_data');
  String get errorOccurred => _t('error_occurred');
  String get retry => _t('retry');
  String get loading => _t('loading');
  String get done => _t('done');
  String get back => _t('back');
  String get noContacts => _t('no_contacts');
  String get noGroups => _t('no_groups');
  String get noMessages => _t('no_messages');
  String get noHistory => _t('no_history');
  String get contactsTab => _t('contacts_tab');
  String get groupsTab => _t('groups_tab');
  String get messagingTab => _t('messaging_tab');
  String get historyTab => _t('history_tab');
  String get settingsTab => _t('settings_tab');
  String get copy => _t('copy');
  String get copySelected => _t('copy_selected');
  String get copyConversation => _t('copy_conversation');
  String get deleteSelected => _t('delete_selected');
  String get noFailedMessages => _t('no_failed_messages');
  String get defaultSmsRoleRequired => _t('default_sms_role_required');
  String retryFailedN(int n) => isArabic ? 'إعادة محاولة الفاشلة ($n)' : 'Retry failed ($n)';
  String selectedCount(int n) => isArabic ? '$n محدد' : '$n selected';

  // contacts module
  String get addContact => _t('add_contact');
  String get editContact => _t('edit_contact');
  String get contactDetail => _t('contact_detail');
  String get firstName => _t('first_name');
  String get lastName => _t('last_name');
  String get phoneNumber => _t('phone_number');
  String get notes => _t('notes');
  String get importContacts => _t('import_contacts');
  String get importFromDevice => _t('import_from_device');
  String get importFromDeviceSubtitle => _t('import_from_device_subtitle');
  String get importFromFile => _t('import_from_file');
  String get importFromFileSubtitle => _t('import_from_file_subtitle');
  String get noNewContactsFound => _t('no_new_contacts_found');
  String get searchContacts => _t('search_contacts');
  String get noResults => _t('no_results');
  String get favorite => _t('favorite');
  String get removeFavorite => _t('remove_favorite');
  String get tags => _t('tags');
  String get noTags => _t('no_tags');
  String get operatorLabel => _t('operator_label');
  String get phoneDisplay => _t('phone_display');
  String get createdDate => _t('created_date');
  String get confirmDelete => _t('confirm_delete');
  String get deleteConfirmation => _t('delete_confirmation');
  String get contactSaved => _t('contact_saved');
  String get contactUpdated => _t('contact_updated');
  String get contactDeleted => _t('contact_deleted');
  String get importSuccess => _t('import_success');
  String get importFailed => _t('import_failed');
  String get importInProgress => _t('import_in_progress');
  String get selectAll => _t('select_all');
  String get clearSelection => _t('clear_selection');
  String get validationRequired => _t('validation_required');
  String get validationInvalidPhone => _t('validation_invalid_phone');
  String get addContactSubtitle => _t('add_contact_subtitle');
  String get importResult => _t('import_result');
  String get contactsImported => _t('contacts_imported');
  String get duplicatesFound => _t('duplicates_found');
  String get skipped => _t('skipped');
  String get total => _t('total');
  String get close => _t('close');
  String get noPhoneNumber => _t('no_phone_number');
  String get selectCountry => _t('select_country');
  String get permissionDenied => _t('permission_denied');
  String get openSettings => _t('open_settings');
  String get allContacts => _t('all_contacts');
  String get favorites => _t('favorites');
  String get noFavorites => _t('no_favorites');
  String get noFavoritesSubtitle => _t('no_favorites_subtitle');
  String get exportContacts => _t('export_contacts');
  String get exportAsVcf => _t('export_as_vcf');
  String get exportAsCsv => _t('export_as_csv');
  String get exportScopeAll => _t('export_scope_all');
  String get exportScopeSelected => _t('export_scope_selected');
  String get exportScopeFavorites => _t('export_scope_favorites');
  String get exportSuccess => _t('export_success');
  String get exportFailed => _t('export_failed');
  String get exportCancelled => _t('export_cancelled');
  String get chooseExportFormat => _t('choose_export_format');
  String get chooseExportScope => _t('choose_export_scope');
  String get export => _t('export');

  // sms / messaging module
  String get compose => _t('compose');
  String get send => _t('send');
  String get messageBody => _t('message_body');
  String get typeMessageHint => _t('type_message_hint');
  String get characters => _t('characters');
  String get segments => _t('segments');
  String get recipientsLabel => _t('recipients_label');
  String get selectRecipients => _t('select_recipients');
  String get messageSent => _t('message_sent');
  String get sendFailed => _t('send_failed');
  String get messageEmptyWarning => _t('message_empty_warning');
  String get noRecipientsWarning => _t('no_recipients_warning');
  String get manualEntry => _t('manual_entry');
  String get enterPhonesHint => _t('enter_phones_hint');
  String get membersLabel => _t('members_label');
  String get groupLabel => _t('group_label');
  String get messageDetail => _t('message_detail');
  String get status => _t('status');
  String get retrySuccess => _t('retry_success');
  String get retryFailed => _t('retry_failed');
  String get sent => _t('sent');
  String get failed => _t('failed');
  String get partial => _t('partial');
  String get queued => _t('queued');
  String get sentAt => _t('sent_at');
  String get templates => _t('templates');
  String get noTemplates => _t('no_templates');
  String get addTemplateSubtitle => _t('add_template_subtitle');
  String get addTemplate => _t('add_template');
  String get editTemplate => _t('edit_template');
  String get templateDeleted => _t('template_deleted');
  String get templateTitle => _t('template_title');
  String get templateBody => _t('template_body');
  String get templateSaved => _t('template_saved');
  String get tapToCompose => _t('tap_to_compose');
  String get justNow => _t('just_now');
  String get smsMessages => _t('sms_messages');
  String get sendSms => _t('send_sms');
  String get sendWhatsApp => _t('send_whatsapp');
  String get viewHistory => _t('view_history');
  String get messagingHubSubtitle => _t('messaging_hub_subtitle');
  String get manageTags => _t('manage_tags');
  String get newTag => _t('new_tag');
  String get enterTagName => _t('enter_tag_name');
  String get createTag => _t('create_tag');
  String get defaultSmsRequired => _t('default_sms_required');
  String get makeDefaultSms => _t('make_default_sms');
  String get makeDefaultSmsDesc => _t('make_default_sms_desc');

  // whatsapp module
  String get whatsapp => _t('whatsapp');
  String get whatsappCompose => _t('whatsapp_compose');
  String get startBatch => _t('start_batch');
  String get assistedFlowDescription => _t('assisted_flow_description');
  String get selectApp => _t('select_app');
  String get preferredApp => _t('preferred_app');
  String get launch => _t('launch');
  String get launchWhatsApp => _t('launch_whatsapp');
  String get markSent => _t('mark_sent');
  String get skip => _t('skip');
  String get batchProgress => _t('batch_progress');
  String get batchComplete => _t('batch_complete');
  String get batchCancelled => _t('batch_cancelled');
  String get confirmCancelBatch => _t('confirm_cancel_batch');
  String get sendManuallyInWhatsApp => _t('send_manually_in_whatsapp');
  String get nextRecipient => _t('next_recipient');
  String get batchHistory => _t('batch_history');
  String get noBatchHistory => _t('no_batch_history');
  String get whatsappApp => _t('whatsapp_app');
  String get whatsappBusiness => _t('whatsapp_business');
  String get launchFailed => _t('launch_failed');
  String get tapToLaunch => _t('tap_to_launch');
  String get noAppInstalled => _t('no_app_installed');
  String get currentRecipient => _t('current_recipient');
  String get completed => _t('completed');
  String get inProgress => _t('in_progress');

  // groups module
  String get addGroup => _t('add_group');
  String get editGroup => _t('edit_group');
  String get renameGroup => _t('rename_group');
  String get groupDetail => _t('group_detail');
  String get groupName => _t('group_name');
  String get groupDescription => _t('group_description');
  String get groupSaved => _t('group_saved');
  String get groupUpdated => _t('group_updated');
  String get groupDeleted => _t('group_deleted');
  String get addGroupSubtitle => _t('add_group_subtitle');
  String get searchGroups => _t('search_groups');
  String get confirmDeleteGroup => _t('confirm_delete_group');
  String get deleteGroupConfirmation => _t('delete_group_confirmation');
  String get addMembers => _t('add_members');
  String get removeMember => _t('remove_member');
  String get addContacts => _t('add_contacts');
  String get noMembers => _t('no_members');
  String get noAvailableContacts => _t('no_available_contacts');

  // history module
  String get timeline => _t('timeline');
  String get historyDetail => _t('history_detail');
  String get allChannels => _t('all_channels');
  String get smsOnly => _t('sms_only');
  String get whatsappOnly => _t('whatsapp_only');
  String get searchHistory => _t('search_history');
  String get deleteEntry => _t('delete_entry');
  String get deleteEntryConfirmation => _t('delete_entry_confirmation');
  String get entryDeleted => _t('entry_deleted');
  String get clearAllHistory => _t('clear_all_history');
  String get clearHistoryConfirmation => _t('clear_history_confirmation');
  String get historyCleared => _t('history_cleared');
  String get successCount => _t('success_count');
  String get failCount => _t('fail_count');
  String get recipientCount => _t('recipient_count');
  String get channel => _t('channel');
  String get retryableEntries => _t('retryable_entries');
  String get failedEntries => _t('failed_entries');
  String get cancelled => _t('cancelled');
  String get historyStats => _t('history_stats');
  String get unknown => _t('unknown');

  // ── Status display labels ────────────────────────────────────────────────
  String get statusSentLabel => _t('status_sent_label');
  String get statusDeliveredLabel => _t('status_delivered_label');
  String get statusFailedLabel => _t('status_failed_label');
  String get statusPartialLabel => _t('status_partial_label');
  String get statusQueuedLabel => _t('status_queued_label');
  String get statusSendingLabel => _t('status_sending_label');
  String get statusReceivedLabel => _t('status_received_label');
  String get statusUnknownLabel => _t('status_unknown_label');

  // ── Filter chip labels ───────────────────────────────────────────────────
  String get filterAllMessages => _t('filter_all_messages');
  String get filterSent => _t('filter_sent');
  String get filterReceived => _t('filter_received');
  String get filterDelivered => _t('filter_delivered');
  String get filterQueued => _t('filter_queued');
  String get filterFailed => _t('filter_failed');
  String get filterPartial => _t('filter_partial');
  String get filterGroups => _t('filter_groups');
  String get filterBroadcasts => _t('filter_broadcasts');
  String get filterIndividual => _t('filter_individual');
  String get filterToday => _t('filter_today');
  String get filterYesterday => _t('filter_yesterday');
  String get filterLast7Days => _t('filter_last_7_days');
  String get filterLastMonth => _t('filter_last_month');
  String get filterStatusLabel => _t('filter_status_label');
  String get filterTypeLabel => _t('filter_type_label');
  String get filterDateLabel => _t('filter_date_label');

  // ── Broadcast display title (parametric) ─────────────────────────────────
  /// e.g. "Broadcast (3 recipients)" / "إرسال جماعي (3 مستلم)"
  String broadcastNRecipients(int count) {
    return _t('broadcast_n_recipients').replaceAll('{count}', count.toString());
  }

  // backup module
  String get backup => _t('backup');
  String get backupAndRestore => _t('backup_and_restore');
  String get createBackup => _t('create_backup');
  String get restore => _t('restore');
  String get backupType => _t('backup_type');
  String get fullSqliteBackup => _t('full_sqlite_backup');
  String get encryptedJsonBackup => _t('encrypted_json_backup');
  String get includeData => _t('include_data');
  String get passphrase => _t('passphrase');
  String get confirmPassphrase => _t('confirm_passphrase');
  String get passphraseRequired => _t('passphrase_required');
  String get passphraseMismatch => _t('passphrase_mismatch');
  String get minChars => _t('min_chars');
  String get encryptWarning => _t('encrypt_warning');
  String get destructiveRestoreWarning => _t('destructive_restore_warning');
  String get confirmRestore => _t('confirm_restore');
  String get restoreInProgress => _t('restore_in_progress');
  String get restoreComplete => _t('restore_complete');
  String get restoreCompletedWithWarnings => _t('restore_completed_with_warnings');
  String get dataRestoredSuccess => _t('data_restored_success');
  String get restoreFailed => _t('restore_failed');
  String get noBackups => _t('no_backups');
  String get noBackupsDesc => _t('no_backups_desc');
  String get deleteBackup => _t('delete_backup');
  String get deleteBackupConfirm => _t('delete_backup_confirm');
  String get contactsRestored => _t('contacts_restored');
  String get smsRestored => _t('sms_restored');
  String get whatsappRestored => _t('whatsapp_restored');
  String get failedItems => _t('failed_items');
  String get entries => _t('entries');
  String get totalEntries => _t('total_entries');
  String get warningsLabel => _t('warnings_label');
  String get validatingFile => _t('validating_file');
  String get creatingBackup => _t('creating_backup');
  String get refresh => _t('refresh');
  String get chooseBackupType => _t('choose_backup_type');
  String get enterPassphrase => _t('enter_passphrase');
  String get setPassphrase => _t('set_passphrase');
  String get backupCreated => _t('backup_created');
  String get import => _t('import');
  String get noBackupFiles => _t('no_backup_files');
  String get noBackupFilesDesc => _t('no_backup_files_desc');
  String get restoreContents => _t('restore_contents');
  String get destructiveOperation => _t('destructive_operation');

  // settings module
  String get settingsLanguage => _t('settings_language');
  String get settingsLanguageSubtitle => _t('settings_language_subtitle');
  String get settingsTheme => _t('settings_theme');
  String get settingsThemeSubtitle => _t('settings_theme_subtitle');
  String get settingsSmsThrottle => _t('settings_sms_throttle');
  String get settingsSmsThrottleSubtitle => _t('settings_sms_throttle_subtitle');
  String get settingsBackup => _t('settings_backup');
  String get settingsBackupSubtitle => _t('settings_backup_subtitle');
  String get settingsAbout => _t('settings_about');
  String get settingsAboutSubtitle => _t('settings_about_subtitle');
  String get settingsEnglish => _t('settings_english');
  String get settingsArabic => _t('settings_arabic');
  String get settingsThemeLight => _t('settings_theme_light');
  String get settingsThemeDark => _t('settings_theme_dark');
  String get settingsThemeSystem => _t('settings_theme_system');
  String get settingsThrottleDesc => _t('settings_throttle_desc');
  String get settingsThrottleNone => _t('settings_throttle_none');
  String get settingsThrottleSeconds => _t('settings_throttle_seconds');
  String get settingsAutoBackup => _t('settings_auto_backup');
  String get settingsAutoBackupDesc => _t('settings_auto_backup_desc');
  String get settingsBackupInterval => _t('settings_backup_interval');
  String get settingsIncludeSms => _t('settings_include_sms');
  String get settingsIncludeWhatsApp => _t('settings_include_whatsapp');
  String get settingsIncludeContacts => _t('settings_include_contacts');
  String get settingsAppName => _t('settings_app_name');
  String get settingsVersion => _t('settings_version');
  String get settingsPackageName => _t('settings_package_name');
  String get settingsReset => _t('settings_reset');
  String get settingsResetConfirm => _t('settings_reset_confirm');
  String get settingsResetDestructive => _t('settings_reset_destructive');
  String get settingsSectionGeneral => _t('settings_section_general');
  String get settingsSectionMessaging => _t('settings_section_messaging');
  String get settingsSectionBackup => _t('settings_section_backup');
  String get settingsSectionAbout => _t('settings_section_about');
  String get settingsDaysLabel => _t('settings_days_label');

  String _t(String key) {
    final map = isArabic ? _ar : _en;
    return map[key] ?? key;
  }

  static const Map<String, String> _en = {
    'app_title': 'Zexano SMS',
    'contacts': 'Contacts',
    'groups': 'Groups',
    'messaging': 'Messaging',
    'history': 'History',
    'settings': 'Settings',
    'search': 'Search',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'confirm': 'Confirm',
    'no_data': 'No data available',
    'error_occurred': 'An error occurred',
    'retry': 'Retry',
    'loading': 'Loading...',
    'done': 'Done',
    'back': 'Back',
    'no_contacts': 'No contacts yet',
    'no_groups': 'No groups yet',
    'no_messages': 'No messages yet',
    'no_history': 'No history yet',
    'contacts_tab': 'Contacts',
    'groups_tab': 'Groups',
    'messaging_tab': 'Messaging',
    'history_tab': 'History',
    'settings_tab': 'Settings',
    'add_contact': 'Add contact',
    'edit_contact': 'Edit contact',
    'contact_detail': 'Contact details',
    'first_name': 'First name',
    'last_name': 'Last name',
    'phone_number': 'Phone number',
    'notes': 'Notes',
    'import_contacts': 'Import contacts',
    'import_from_device': 'Import from device',
    'import_from_device_subtitle': 'Import contacts from your phone\'s address book',
    'import_from_file': 'Import from file',
    'import_from_file_subtitle': 'Import contacts from a CSV or vCard file',
    'no_new_contacts_found': 'No new contacts found to import',
    'search_contacts': 'Search contacts',
    'no_results': 'No results found',
    'favorite': 'Favorite',
    'remove_favorite': 'Remove from favorites',
    'tags': 'Tags',
    'no_tags': 'No tags',
    'operator_label': 'Operator',
    'phone_display': 'Phone',
    'created_date': 'Added on',
    'confirm_delete': 'Delete contact',
    'delete_confirmation': 'Are you sure you want to delete this contact?',
    'contact_saved': 'Contact saved successfully',
    'contact_updated': 'Contact updated successfully',
    'contact_deleted': 'Contact deleted',
    'import_success': 'Contacts imported successfully',
    'import_failed': 'Failed to import contacts',
    'import_in_progress': 'Importing contacts...',
    'select_all': 'Select all',
    'clear_selection': 'Clear selection',
    'validation_required': 'This field is required',
    'validation_invalid_phone': 'Please enter a valid phone number',
    'add_contact_subtitle': 'Add a new contact to your address book',
    'import_result': 'Import Result',
    'contacts_imported': 'Imported',
    'duplicates_found': 'Duplicates',
    'skipped': 'Skipped',
    'total': 'Total',
    'close': 'Close',
    'no_phone_number': 'No phone number',
    'select_country': 'Select country code',
    'permission_denied': 'Contacts permission denied. Please allow access in Settings.',
    'open_settings': 'Open Settings',
    'all_contacts': 'All Contacts',
    'favorites': 'Favorites',
    'no_favorites': 'No favorite contacts',
    'no_favorites_subtitle': 'Tap the star icon next to any contact to add it to favorites',
    'export_contacts': 'Export Contacts',
    'export_as_vcf': 'Export as VCF (vCard)',
    'export_as_csv': 'Export as CSV',
    'export_scope_all': 'All Contacts',
    'export_scope_selected': 'Selected Contacts',
    'export_scope_favorites': 'Favorites Only',
    'export_success': 'Contacts exported successfully',
    'export_failed': 'Failed to export contacts',
    'export_cancelled': 'Export cancelled',
    'choose_export_format': 'Choose Export Format',
    'choose_export_scope': 'Choose Export Scope',
    'export': 'Export',
    'compose': 'Compose',
    'send': 'Send',
    'message_body': 'Message body',
    'type_message_hint': 'Type your message here...',
    'characters': 'characters',
    'segments': 'segments',
    'recipients_label': 'Recipients',
    'select_recipients': 'Select recipients',
    'message_sent': 'Message sent successfully',
    'send_failed': 'Failed to send message',
    'message_empty_warning': 'Please enter a message',
    'no_recipients_warning': 'Please select at least one recipient',
    'manual_entry': 'Manual entry',
    'enter_phones_hint': 'Enter phone numbers, one per line',
    'members_label': 'members',
    'group_label': 'Group',
    'message_detail': 'Message details',
    'status': 'Status',
    'retry_success': 'Retry completed',
    'retry_failed': 'Retry failed',
    'sent': 'Sent',
    'failed': 'Failed',
    'partial': 'Partial',
    'queued': 'Queued',
    'sent_at': 'Sent at',
    'templates': 'Templates',
    'no_templates': 'No templates yet',
    'add_template_subtitle': 'Create a template for quick message creation',
    'add_template': 'Add template',
    'edit_template': 'Edit template',
    'template_deleted': 'Template deleted',
    'template_title': 'Template title',
    'template_body': 'Template body',
    'template_saved': 'Template saved successfully',
    'tap_to_compose': 'Tap + to compose a new message',
    'just_now': 'Just now',
    'sms_messages': 'SMS Messages',
    'send_sms': 'Send SMS',
    'send_whatsapp': 'Send WhatsApp',
    'view_history': 'View History',
    'messaging_hub_subtitle': 'Choose a channel to send your message',
    'manage_tags': 'Manage Tags',
    'new_tag': 'New tag',
    'enter_tag_name': 'Enter tag name',
    'create_tag': 'Create',
    'default_sms_required': 'Default SMS app required',
    'default_sms_role_required': 'Set Zexano as default SMS app to send messages',
    'copy': 'Copy',
    'copy_selected': 'Copy selected',
    'copy_conversation': 'Copy conversation',
    'delete_selected': 'Delete selected',
    'no_failed_messages': 'No failed messages',
    'make_default_sms': 'Set as default SMS app',
    'make_default_sms_desc': 'To send SMS messages, Zexano SMS needs to be set as your default SMS app. Your current default SMS app will still work normally for other messaging needs.',
    'whatsapp': 'WhatsApp',
    'whatsapp_compose': 'WhatsApp Compose',
    'start_batch': 'Start Assisted Batch',
    'assisted_flow_description': 'Send each message manually in WhatsApp. We\'ll open WhatsApp for each recipient one by one.',
    'select_app': 'Select App',
    'preferred_app': 'Preferred WhatsApp App',
    'launch': 'Launch',
    'launch_whatsapp': 'Open in WhatsApp',
    'mark_sent': 'Mark Sent',
    'skip': 'Skip',
    'batch_progress': 'Batch Progress',
    'batch_complete': 'All messages processed!',
    'batch_cancelled': 'Cancelled',
    'confirm_cancel_batch': 'Cancel this batch?',
    'send_manually_in_whatsapp': 'Tap the button to open WhatsApp, then send the message manually.',
    'next_recipient': 'Next Recipient',
    'batch_history': 'Batch History',
    'no_batch_history': 'No WhatsApp batches yet',
    'whatsapp_app': 'WhatsApp',
    'whatsapp_business': 'WhatsApp Business',
    'launch_failed': 'Failed to launch WhatsApp',
    'tap_to_launch': 'Tap to open WhatsApp',
    'no_app_installed': 'No WhatsApp app is installed on this device',
    'current_recipient': 'Current Recipient',
    'completed': 'Completed',
    'in_progress': 'In Progress',
    'add_group': 'Add group',
    'edit_group': 'Edit group',
    'rename_group': 'Rename group',
    'group_detail': 'Group details',
    'group_name': 'Group name',
    'group_description': 'Description',
    'group_saved': 'Group created successfully',
    'group_updated': 'Group updated successfully',
    'group_deleted': 'Group deleted',
    'add_group_subtitle': 'Create a group to organize your contacts',
    'search_groups': 'Search groups',
    'confirm_delete_group': 'Delete group',
    'delete_group_confirmation': 'Are you sure you want to delete this group?',
    'add_members': 'Add members',
    'remove_member': 'Remove member',
    'add_contacts': 'Add contacts',
    'no_members': 'No members in this group',
    'no_available_contacts': 'No contacts available to add',
    'timeline': 'Timeline',
    'history_detail': 'History Detail',
    'all_channels': 'All Channels',
    'sms_only': 'SMS',
    'whatsapp_only': 'WhatsApp',
    'search_history': 'Search history',
    'delete_entry': 'Delete entry',
    'delete_entry_confirmation': 'Are you sure you want to delete this entry?',
    'entry_deleted': 'Entry deleted',
    'clear_all_history': 'Clear all history',
    'clear_history_confirmation': 'Are you sure you want to clear all history?',
    'history_cleared': 'History cleared',
    'success_count': 'Successful',
    'fail_count': 'Failed',
    'recipient_count': 'Recipients',
    'channel': 'Channel',
    'retryable_entries': 'Retryable Entries',
    'failed_entries': 'Failed Entries',
    'cancelled': 'Cancelled',
    'history_stats': 'History Stats',
    'unknown': 'Unknown',
    // status display labels
    'status_sent_label':      '✓ Sent',
    'status_delivered_label': '✓ Delivered',
    'status_failed_label':    '✗ Failed',
    'status_partial_label':   '⚠ Partial',
    'status_queued_label':    '⏳ Queued',
    'status_sending_label':   '⏳ Sending',
    'status_received_label':  '↓ Received',
    'status_unknown_label':   '? Unknown',
    // filter chip labels
    'filter_all_messages':  'All Messages',
    'filter_sent':          'Sent',
    'filter_received':      'Received',
    'filter_delivered':     'Delivered',
    'filter_queued':        'Queued',
    'filter_failed':        'Failed',
    'filter_partial':       'Partial',
    'filter_groups':        'Groups',
    'filter_broadcasts':    'Broadcasts',
    'filter_individual':    'Individual',
    'filter_today':         'Today',
    'filter_yesterday':     'Yesterday',
    'filter_last_7_days':   'Last 7 Days',
    'filter_last_month':    'Last Month',
    'filter_status_label':  'Status',
    'filter_type_label':    'Type',
    'filter_date_label':    'Date',
    // broadcast title
    'broadcast_n_recipients': 'Broadcast ({count} recipients)',
    'backup': 'Backup',
    'backup_and_restore': 'Backup & Restore',
    'create_backup': 'Create Backup',
    'restore': 'Restore',
    'backup_type': 'Backup Type',
    'full_sqlite_backup': 'Full SQLite Backup',
    'encrypted_json_backup': 'Encrypted JSON Backup',
    'include_data': 'Include Data',
    'passphrase': 'Passphrase',
    'confirm_passphrase': 'Confirm Passphrase',
    'passphrase_required': 'Passphrase required',
    'passphrase_mismatch': 'Passphrases do not match',
    'min_chars': 'At least 8 characters',
    'encrypt_warning': 'If you lose the passphrase, the backup cannot be recovered.',
    'destructive_restore_warning': 'Restoring will replace ALL existing data. Current contacts, messages, and history will be overwritten.',
    'confirm_restore': 'Yes, Restore',
    'restore_in_progress': 'Restoring data...',
    'restore_complete': 'Restore Complete',
    'restore_completed_with_warnings': 'Restore completed with warnings',
    'data_restored_success': 'Data restored successfully',
    'restore_failed': 'Restore Failed',
    'no_backups': 'No backups yet',
    'no_backups_desc': 'Create your first backup to protect your data.',
    'delete_backup': 'Delete Backup',
    'delete_backup_confirm': 'Delete this backup? This cannot be undone.',
    'contacts_restored': 'Contacts restored',
    'sms_restored': 'SMS messages restored',
    'whatsapp_restored': 'WhatsApp sessions restored',
    'failed_items': 'Failed items',
    'entries': 'entries',
    'total_entries': 'Total entries',
    'warnings_label': 'Warnings',
    'validating_file': 'Validating backup file...',
    'creating_backup': 'Creating backup...',
    'refresh': 'Refresh',
    'choose_backup_type': 'Choose backup type',
    'enter_passphrase': 'Enter passphrase to decrypt',
    'set_passphrase': 'Set Passphrase',
    'backup_created': 'Backup created successfully',
    'import': 'Import',
    'no_backup_files': 'No backup files found',
    'no_backup_files_desc': 'Create a backup first, then return here to restore.',
    'restore_contents': 'Backup contents',
    'destructive_operation': 'Destructive operation',

    // settings module
    'settings_language': 'Language',
    'settings_language_subtitle': 'English / العربية',
    'settings_theme': 'Theme',
    'settings_theme_subtitle': 'Light / Dark / System',
    'settings_sms_throttle': 'SMS Throttle',
    'settings_sms_throttle_subtitle': 'Delay between consecutive messages',
    'settings_backup': 'Backup Settings',
    'settings_backup_subtitle': 'Auto-backup and data preferences',
    'settings_about': 'About',
    'settings_about_subtitle': 'App info and reset options',
    'settings_english': 'English',
    'settings_arabic': 'Arabic',
    'settings_theme_light': 'Light',
    'settings_theme_dark': 'Dark',
    'settings_theme_system': 'System Default',
    'settings_throttle_desc': 'Minimum delay between sending consecutive SMS messages.',
    'settings_throttle_none': 'No delay',
    'settings_throttle_seconds': 'seconds',
    'settings_auto_backup': 'Automatic Backup',
    'settings_auto_backup_desc': 'Automatically create backups on a regular schedule',
    'settings_backup_interval': 'Backup interval',
    'settings_include_sms': 'Include SMS messages',
    'settings_include_whatsapp': 'Include WhatsApp sessions',
    'settings_include_contacts': 'Include contacts',
    'settings_app_name': 'App Name',
    'settings_version': 'Version',
    'settings_package_name': 'Package Name',
    'settings_reset': 'Reset Settings',
    'settings_reset_confirm': 'Are you sure you want to reset all non-destructive settings to defaults?',
    'settings_reset_destructive': 'Language and theme preferences will be preserved.',
    'settings_section_general': 'General',
    'settings_section_messaging': 'Messaging',
    'settings_section_backup': 'Backup',
    'settings_section_about': 'About',
    'settings_days_label': 'days',
  };

  static const Map<String, String> _ar = {
    'app_title': 'Zexano SMS',
    'contacts': 'جهات الاتصال',
    'groups': 'المجموعات',
    'messaging': 'الرسائل',
    'history': 'السجل',
    'settings': 'الإعدادات',
    'search': 'بحث',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'delete': 'حذف',
    'confirm': 'تأكيد',
    'no_data': 'لا توجد بيانات',
    'error_occurred': 'حدث خطأ',
    'retry': 'إعادة المحاولة',
    'loading': 'جارٍ التحميل...',
    'done': 'تم',
    'back': 'رجوع',
    'no_contacts': 'لا توجد جهات اتصال بعد',
    'no_groups': 'لا توجد مجموعات بعد',
    'no_messages': 'لا توجد رسائل بعد',
    'no_history': 'لا يوجد سجل بعد',
    'contacts_tab': 'جهات الاتصال',
    'groups_tab': 'المجموعات',
    'messaging_tab': 'الرسائل',
    'history_tab': 'السجل',
    'settings_tab': 'الإعدادات',
    'add_contact': 'إضافة جهة اتصال',
    'edit_contact': 'تعديل جهة اتصال',
    'contact_detail': 'تفاصيل جهة الاتصال',
    'first_name': 'الاسم الأول',
    'last_name': 'اسم العائلة',
    'phone_number': 'رقم الهاتف',
    'notes': 'ملاحظات',
    'import_contacts': 'استيراد جهات الاتصال',
    'import_from_device': 'استيراد من الجهاز',
    'import_from_device_subtitle': 'استيراد جهات الاتصال من دفتر عناوين الهاتف',
    'import_from_file': 'استيراد من ملف',
    'import_from_file_subtitle': 'استيراد جهات الاتصال من ملف CSV أو vCard',
    'no_new_contacts_found': 'لم يتم العثور على جهات اتصال جديدة للاستيراد',
    'search_contacts': 'بحث في جهات الاتصال',
    'no_results': 'لا توجد نتائج',
    'favorite': 'مفضلة',
    'remove_favorite': 'إزالة من المفضلة',
    'tags': 'الوسوم',
    'no_tags': 'لا توجد وسوم',
    'operator_label': 'المشغل',
    'phone_display': 'الهاتف',
    'created_date': 'أُضيف في',
    'confirm_delete': 'حذف جهة الاتصال',
    'delete_confirmation': 'هل أنت متأكد من حذف جهة الاتصال هذه؟',
    'contact_saved': 'تم حفظ جهة الاتصال بنجاح',
    'contact_updated': 'تم تحديث جهة الاتصال بنجاح',
    'contact_deleted': 'تم حذف جهة الاتصال',
    'import_success': 'تم استيراد جهات الاتصال بنجاح',
    'import_failed': 'فشل استيراد جهات الاتصال',
    'import_in_progress': 'جارٍ استيراد جهات الاتصال...',
    'select_all': 'تحديد الكل',
    'clear_selection': 'إلغاء التحديد',
    'validation_required': 'هذا الحقل مطلوب',
    'validation_invalid_phone': 'يرجى إدخال رقم هاتف صحيح',
    'add_contact_subtitle': 'أضف جهة اتصال جديدة إلى دفتر العناوين',
    'import_result': 'نتيجة الاستيراد',
    'contacts_imported': 'تم الاستيراد',
    'duplicates_found': 'مكررات',
    'skipped': 'تم التخطي',
    'total': 'الإجمالي',
    'close': 'إغلاق',
    'no_phone_number': 'لا يوجد رقم هاتف',
    'select_country': 'اختر رمز الدولة',
    'permission_denied': 'تم رفض إذن جهات الاتصال. يرجى السماح بالوصول من الإعدادات.',
    'open_settings': 'فتح الإعدادات',
    'all_contacts': 'جميع جهات الاتصال',
    'favorites': 'المفضلة',
    'no_favorites': 'لا توجد جهات اتصال مفضلة',
    'no_favorites_subtitle': 'اضغط على رمز النجمة بجانب أي جهة اتصال لإضافتها إلى المفضلة',
    'export_contacts': 'تصدير جهات الاتصال',
    'export_as_vcf': 'تصدير بصيغة VCF (vCard)',
    'export_as_csv': 'تصدير بصيغة CSV',
    'export_scope_all': 'جميع جهات الاتصال',
    'export_scope_selected': 'جهات الاتصال المحددة',
    'export_scope_favorites': 'المفضلة فقط',
    'export_success': 'تم تصدير جهات الاتصال بنجاح',
    'export_failed': 'فشل تصدير جهات الاتصال',
    'export_cancelled': 'تم إلغاء التصدير',
    'choose_export_format': 'اختر صيغة التصدير',
    'choose_export_scope': 'اختر نطاق التصدير',
    'export': 'تصدير',
    'compose': 'إنشاء رسالة',
    'send': 'إرسال',
    'message_body': 'نص الرسالة',
    'type_message_hint': 'اكتب رسالتك هنا...',
    'characters': 'حرف',
    'segments': 'شريحة',
    'recipients_label': 'المستلمون',
    'select_recipients': 'اختر المستلمين',
    'message_sent': 'تم إرسال الرسالة بنجاح',
    'send_failed': 'فشل إرسال الرسالة',
    'message_empty_warning': 'يرجى إدخال نص الرسالة',
    'no_recipients_warning': 'يرجى اختيار مستلم واحد على الأقل',
    'manual_entry': 'إدخال يدوي',
    'enter_phones_hint': 'أدخل أرقام الهواتف، رقم في كل سطر',
    'members_label': 'عضو',
    'group_label': 'المجموعة',
    'message_detail': 'تفاصيل الرسالة',
    'status': 'الحالة',
    'retry_success': 'تمت إعادة المحاولة',
    'retry_failed': 'فشلت إعادة المحاولة',
    'sent': 'تم الإرسال',
    'failed': 'فشل',
    'partial': 'جزئي',
    'queued': 'في الانتظار',
    'sent_at': 'أُرسلت في',
    'templates': 'القوالب',
    'no_templates': 'لا توجد قوالب بعد',
    'add_template_subtitle': 'أنشئ قالباً لإنشاء رسائل سريعة',
    'add_template': 'إضافة قالب',
    'edit_template': 'تعديل القالب',
    'template_deleted': 'تم حذف القالب',
    'template_title': 'عنوان القالب',
    'template_body': 'نص القالب',
    'template_saved': 'تم حفظ القالب بنجاح',
    'tap_to_compose': 'اضغط + لإنشاء رسالة جديدة',
    'just_now': 'الآن',
    'sms_messages': 'رسائل SMS',
    'send_sms': 'إرسال SMS',
    'send_whatsapp': 'إرسال واتساب',
    'view_history': 'عرض السجل',
    'messaging_hub_subtitle': 'اختر قناة لإرسال رسالتك',
    'manage_tags': 'إدارة الوسوم',
    'new_tag': 'وسم جديد',
    'enter_tag_name': 'أدخل اسم الوسم',
    'create_tag': 'إنشاء',
    'default_sms_required': 'تطبيق SMS الافتراضي مطلوب',
    'make_default_sms': 'تعيين كتطبيق افتراضي للرسائل',
    'make_default_sms_desc': 'لإرسال رسائل SMS، يجب تعيين زيكسانو كتطبيق الرسائل الافتراضي. تطبيق الرسائل الافتراضي الحالي سيظل يعمل بشكل طبيعي للرسائل الأخرى.',
    'whatsapp': 'واتساب',
    'whatsapp_compose': 'إنشاء رسالة واتساب',
    'start_batch': 'بدء الإرسال المساعد',
    'assisted_flow_description': 'أرسل كل رسالة يدوياً في واتساب. سنفتح واتساب لكل مستلم واحد تلو الآخر.',
    'select_app': 'اختيار التطبيق',
    'preferred_app': 'تطبيق واتساب المفضل',
    'launch': 'فتح',
    'launch_whatsapp': 'فتح في واتساب',
    'mark_sent': 'تأكيد الإرسال',
    'skip': 'تخطي',
    'batch_progress': 'تقدم الدفعة',
    'batch_complete': 'تمت معالجة جميع الرسائل!',
    'batch_cancelled': 'ملغية',
    'confirm_cancel_batch': 'إلغاء هذه الدفعة؟',
    'send_manually_in_whatsapp': 'اضغط على الزر لفتح واتساب، ثم أرسل الرسالة يدوياً.',
    'next_recipient': 'المستلم التالي',
    'batch_history': 'سجل الدفعات',
    'no_batch_history': 'لا توجد دفعات واتساب بعد',
    'whatsapp_app': 'واتساب',
    'whatsapp_business': 'واتساب للأعمال',
    'launch_failed': 'فشل فتح واتساب',
    'tap_to_launch': 'اضغط لفتح واتساب',
    'no_app_installed': 'لم يتم تثبيت تطبيق واتساب على هذا الجهاز',
    'current_recipient': 'المستلم الحالي',
    'completed': 'مكتمل',
    'in_progress': 'قيد التنفيذ',
    'add_group': 'إضافة مجموعة',
    'edit_group': 'تعديل المجموعة',
    'rename_group': 'إعادة تسمية',
    'group_detail': 'تفاصيل المجموعة',
    'group_name': 'اسم المجموعة',
    'group_description': 'الوصف',
    'group_saved': 'تم إنشاء المجموعة بنجاح',
    'group_updated': 'تم تحديث المجموعة بنجاح',
    'group_deleted': 'تم حذف المجموعة',
    'add_group_subtitle': 'أنشئ مجموعة لتنظيم جهات اتصالك',
    'search_groups': 'بحث في المجموعات',
    'confirm_delete_group': 'حذف المجموعة',
    'delete_group_confirmation': 'هل أنت متأكد من حذف هذه المجموعة؟',
    'add_members': 'إضافة أعضاء',
    'remove_member': 'إزالة عضو',
    'add_contacts': 'إضافة جهات اتصال',
    'no_members': 'لا يوجد أعضاء في هذه المجموعة',
    'no_available_contacts': 'لا توجد جهات اتصال متاحة للإضافة',
    'timeline': 'الخط الزمني',
    'history_detail': 'تفاصيل السجل',
    'all_channels': 'جميع القنوات',
    'sms_only': 'رسائل نصية',
    'whatsapp_only': 'واتساب',
    'search_history': 'بحث في السجل',
    'delete_entry': 'حذف الإدخال',
    'delete_entry_confirmation': 'هل أنت متأكد من حذف هذا الإدخال؟',
    'entry_deleted': 'تم حذف الإدخال',
    'clear_all_history': 'مسح كل السجل',
    'clear_history_confirmation': 'هل أنت متأكد من مسح كل السجل؟',
    'history_cleared': 'تم مسح السجل',
    'success_count': 'ناجحة',
    'fail_count': 'فاشلة',
    'recipient_count': 'المستلمون',
    'channel': 'القناة',
    'retryable_entries': 'قابلة لإعادة المحاولة',
    'failed_entries': 'الإدخالات الفاشلة',
    'cancelled': 'ملغية',
    'history_stats': 'إحصائيات السجل',
    'unknown': 'غير معروف',
    'default_sms_role_required': 'يجب تعيين التطبيق كتطبيق الرسائل الافتراضي لإرسال الرسائل',
    'copy': 'نسخ',
    'copy_selected': 'نسخ المحدد',
    'copy_conversation': 'نسخ المحادثة',
    'delete_selected': 'حذف المحدد',
    'no_failed_messages': 'لا توجد رسائل فاشلة',
    // status display labels
    'status_sent_label':      '✓ مُرسَل',
    'status_delivered_label': '✓ تم التسليم',
    'status_failed_label':    '✗ فشل',
    'status_partial_label':   '⚠ جزئي',
    'status_queued_label':    '⏳ في الانتظار',
    'status_sending_label':   '⏳ جارٍ الإرسال',
    'status_received_label':  '↓ وارد',
    'status_unknown_label':   '? غير معروف',
    // filter chip labels
    'filter_all_messages':  'جميع الرسائل',
    'filter_sent':          'المُرسَلة',
    'filter_received':      'الواردة',
    'filter_delivered':     'تم التسليم',
    'filter_queued':        'في الانتظار',
    'filter_failed':        'الفاشلة',
    'filter_partial':       'الجزئية',
    'filter_groups':        'المجموعات',
    'filter_broadcasts':    'الإرسال الجماعي',
    'filter_individual':    'فردية',
    'filter_today':         'اليوم',
    'filter_yesterday':     'الأمس',
    'filter_last_7_days':   'آخر 7 أيام',
    'filter_last_month':    'الشهر الماضي',
    'filter_status_label':  'الحالة',
    'filter_type_label':    'النوع',
    'filter_date_label':    'التاريخ',
    // broadcast title
    'broadcast_n_recipients': 'إرسال جماعي ({count} مستلم)',
    'backup': 'النسخ الاحتياطي',
    'backup_and_restore': 'النسخ الاحتياطي والاستعادة',
    'create_backup': 'إنشاء نسخة احتياطية',
    'restore': 'استعادة',
    'backup_type': 'نوع النسخ الاحتياطي',
    'full_sqlite_backup': 'نسخة SQLite كاملة',
    'encrypted_json_backup': 'نسخة JSON مشفرة',
    'include_data': 'تضمين البيانات',
    'passphrase': 'كلمة المرور',
    'confirm_passphrase': 'تأكيد كلمة المرور',
    'passphrase_required': 'كلمة المرور مطلوبة',
    'passphrase_mismatch': 'كلمتا المرور غير متطابقتين',
    'min_chars': '8 أحرف على الأقل',
    'encrypt_warning': 'إذا فقدت كلمة المرور، لا يمكن استعادة النسخة الاحتياطية.',
    'destructive_restore_warning': 'الاستعادة ستستبدل جميع البيانات الحالية. سيتم استبدال جهات الاتصال والرسائل والسجل.',
    'confirm_restore': 'نعم، استعادة',
    'restore_in_progress': 'جارٍ استعادة البيانات...',
    'restore_complete': 'اكتملت الاستعادة',
    'restore_completed_with_warnings': 'اكتملت الاستعادة مع تحذيرات',
    'data_restored_success': 'تمت استعادة البيانات بنجاح',
    'restore_failed': 'فشلت الاستعادة',
    'no_backups': 'لا توجد نسخ احتياطية بعد',
    'no_backups_desc': 'أنشئ نسختك الاحتياطية الأولى لحماية بياناتك.',
    'delete_backup': 'حذف النسخة الاحتياطية',
    'delete_backup_confirm': 'حذف هذه النسخة؟ لا يمكن التراجع عن هذا الإجراء.',
    'contacts_restored': 'تم استعادة جهات الاتصال',
    'sms_restored': 'تم استعادة رسائل SMS',
    'whatsapp_restored': 'تم استعادة جلسات واتساب',
    'failed_items': 'العناصر الفاشلة',
    'entries': 'مدخل',
    'total_entries': 'إجمالي المدخلات',
    'warnings_label': 'تحذيرات',
    'validating_file': 'جارٍ التحقق من صحة الملف...',
    'creating_backup': 'جارٍ إنشاء النسخة الاحتياطية...',
    'refresh': 'تحديث',
    'choose_backup_type': 'اختر نوع النسخة الاحتياطية',
    'enter_passphrase': 'أدخل كلمة المرور لفك التشفير',
    'set_passphrase': 'تعيين كلمة المرور',
    'backup_created': 'تم إنشاء النسخة الاحتياطية بنجاح',
    'import': 'استيراد',
    'no_backup_files': 'لم يتم العثور على ملفات نسخ احتياطي',
    'no_backup_files_desc': 'أنشئ نسخة احتياطية أولاً، ثم عد لاستعادتها.',
    'restore_contents': 'محتويات النسخة الاحتياطية',
    'destructive_operation': 'عملية استبدال كاملة',

    // settings module
    'settings_language': 'اللغة',
    'settings_language_subtitle': 'English / العربية',
    'settings_theme': 'المظهر',
    'settings_theme_subtitle': 'فاتح / مظلم / تلقائي',
    'settings_sms_throttle': 'التحكم في إرسال SMS',
    'settings_sms_throttle_subtitle': 'التأخير بين الرسائل المتتالية',
    'settings_backup': 'إعدادات النسخ الاحتياطي',
    'settings_backup_subtitle': 'النسخ التلقائي وتفضيلات البيانات',
    'settings_about': 'حول',
    'settings_about_subtitle': 'معلومات التطبيق وخيارات إعادة الضبط',
    'settings_english': 'الإنجليزية',
    'settings_arabic': 'العربية',
    'settings_theme_light': 'فاتح',
    'settings_theme_dark': 'مظلم',
    'settings_theme_system': 'إعدادات النظام',
    'settings_throttle_desc': 'أقل فترة زمنية بين إرسال الرسائل النصية المتتالية.',
    'settings_throttle_none': 'بدون تأخير',
    'settings_throttle_seconds': 'ثانية',
    'settings_auto_backup': 'النسخ الاحتياطي التلقائي',
    'settings_auto_backup_desc': 'إنشاء نسخ احتياطية تلقائياً بشكل دوري',
    'settings_backup_interval': 'فترة النسخ الاحتياطي',
    'settings_include_sms': 'تضمين رسائل SMS',
    'settings_include_whatsapp': 'تضمين جلسات واتساب',
    'settings_include_contacts': 'تضمين جهات الاتصال',
    'settings_app_name': 'اسم التطبيق',
    'settings_version': 'الإصدار',
    'settings_package_name': 'اسم الحزمة',
    'settings_reset': 'إعادة ضبط الإعدادات',
    'settings_reset_confirm': 'هل أنت متأكد من إعادة ضبط جميع الإعدادات غير التدميرية إلى الوضع الافتراضي؟',
    'settings_reset_destructive': 'سيتم الاحتفاظ بتفضيلات اللغة والمظهر.',
    'settings_section_general': 'عام',
    'settings_section_messaging': 'الرسائل',
    'settings_section_backup': 'النسخ الاحتياطي',
    'settings_section_about': 'حول',
    'settings_days_label': 'أيام',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations._languages.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
