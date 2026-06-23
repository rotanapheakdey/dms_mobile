import 'package:flutter/material.dart';

// Extension for easy access: context.l10n
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isKhmer => locale.languageCode == 'km';

  String _t(String en, String km) => isKhmer ? km : en;

  // ─── APP ───
  String get appTitle => _t('DMS', 'DMS');
  String get appVersion => _t('DMS System v1.0.0', 'ប្រព័ន្ធ DMS v1.0.0');

  // ─── AUTH ───
  String get login => _t('Login', 'ចូលប្រើប្រាស់');
  String get logout => _t('Log Out', 'ចេញពីប្រព័ន្ធ');
  String get email => _t('Email', 'អ៊ីមែល');
  String get password => _t('Password', 'លេខសម្ងាត់');
  String get emailHint => _t('Enter your email', 'បញ្ចូលអ៊ីមែលរបស់អ្នក');
  String get passwordHint => _t('Enter your password', 'បញ្ចូលលេខសម្ងាត់');
  String get emailRequired => _t('Email is required', 'ត្រូវការអ៊ីមែល');
  String get validEmail => _t('Enter a valid email', 'បញ្ចូលអ៊ីមែលត្រឹមត្រូវ');
  String get passwordRequired => _t('Password is required', 'ត្រូវការលេខសម្ងាត់');
  String get passwordMinLength => _t('Password must be at least 6 characters', 'លេខសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួអក្សរ');
  String get welcomeBack => _t('Welcome Back', 'សូមស្វាគមន៍ការ귀 ');
  String get loginSubtitle => _t('Sign in to your account', 'ចូលទៅគណនីរបស់អ្នក');
  String get signingIn => _t('Signing in...', 'កំពុងចូល...');

  // ─── NAV ───
  String get navHome => _t('Home', 'ទំព័រដើម');
  String get navArchive => _t('Archive', 'បណ្ណសារ');
  String get navNotifications => _t('Notifications', 'ការជូនដំណឹង');
  String get navProfile => _t('Profile', 'ប្រវត្តិរូប');

  // ─── DASHBOARD ───
  String get dashboard => _t('Dashboard', 'ផ្ទាំងគ្រប់គ្រង');
  String get goodMorning => _t('Good Morning', 'អរុណសួស្តី');
  String get goodAfternoon => _t('Good Afternoon', 'ទិវាសួស្តី');
  String get goodEvening => _t('Good Evening', 'សាយ័ណ្ហសួស្តី');
  String get urgentDocuments => _t('Urgent Documents', 'ឯកសារបន្ទាន់');
  String get noUrgentDocs => _t('No urgent documents', 'គ្មានឯកសារបន្ទាន់');
  String get allCaughtUp => _t('You\'re all caught up!', 'អ្នកបានស្ទាក់ស្ទើរទាំងអស់!');
  String get uploadDocument => _t('Upload Document', 'បញ្ចូលឯកសារ');
  String get viewAll => _t('View All', 'មើលទាំងអស់');
  String get refresh => _t('Refresh', 'ធ្វើឱ្យស្រស់');

  // ─── DOCUMENTS ───
  String get documents => _t('Documents', 'ឯកសារ');
  String get documentList => _t('Document List', 'បញ្ជីឯកសារ');
  String get documentDetail => _t('Document Detail', 'ព័ត៌មានលម្អិតឯកសារ');
  String get documentTitle => _t('Document Title', 'ចំណងជើងឯកសារ');
  String get documentTitleHint => _t('Enter document title', 'បញ្ចូលចំណងជើងឯកសារ');
  String get documentTitleRequired => _t('A title is required', 'ត្រូវការចំណងជើង');
  String get controlNo => _t('Control No.', 'លេខគ្រប់គ្រង');
  String get uploadedBy => _t('Uploaded by', 'បញ្ចូលដោយ');
  String get assignedTo => _t('Assigned to', 'ដាក់ភារៈដល់');
  String get createdAt => _t('Created', 'បានបង្កើត');
  String get updatedAt => _t('Updated', 'បានធ្វើបច្ចុប្បន្នភាព');
  String get unassigned => _t('Unassigned', 'មិនទាន់ដាក់ភារៈ');
  String get noDocuments => _t('No Documents', 'គ្មានឯកសារ');
  String get noDocumentsFound => _t('No documents found', 'រកមិនឃើញឯកសារ');
  String get searchDocuments => _t('Search documents...', 'ស្វែងរកឯកសារ...');
  String get allDocuments => _t('All', 'ទាំងអស់');
  String get comment => _t('Comment', 'មតិយោបល់');
  String get commentHint => _t('Additional comments (Optional)', 'មតិយោបល់បន្ថែម (ស្រេចចិត្ត)');
  String get newDocument => _t('New Document', 'ឯកសារថ្មី');
  String get documentDetails => _t('Document Details', 'ព័ត៌មានលម្អិតឯកសារ');
  String get fileAttachment => _t('File Attachment', 'ឯកសារភ្ជាប់');
  String get tapToBrowse => _t('Tap to browse files', 'ចុចដើម្បីរកឯកសារ');
  String get supportedFormats => _t('Supported formats: PDF, DOC, DOCX\nMaximum size: 10MB', 'ទម្រង់ដែលគាំទ្រ: PDF, DOC, DOCX\nទំហំអតិបរមា: 10MB');
  String get uploading => _t('Uploading document...', 'កំពុងបញ្ចូលឯកសារ...');
  String get uploadSuccess => _t('Document uploaded successfully!', 'បញ្ចូលឯកសារជោគជ័យ!');
  String get uploadFailed => _t('Upload failed. Please try again.', 'ការបញ្ចូលបានបរាជ័យ។ សូមព្យាយាមម្តងទៀត។');
  String get cancel => _t('Cancel', 'បោះបង់');
  String get confirm => _t('Confirm', 'បញ្ជាក់');
  String get loading => _t('Loading...', 'កំពុងផ្ទុក...');
  String get loadingDocuments => _t('Loading documents...', 'កំពុងផ្ទុកឯកសារ...');
  String get noInternetConnection => _t('No internet connection.', 'គ្មានការតភ្ជាប់អ៊ីនធឺណិត។');

  // ─── DOCUMENT ACTIONS ───
  String get assignDepartment => _t('Assign Department', 'ដាក់ភារៈទៅផ្នែក');
  String get dispatch => _t('Dispatch', 'បញ្ជូន');
  String get uploadReport => _t('Upload Report', 'បញ្ចូលរបាយការណ៍');
  String get signVDG => _t('Sign (VDG)', 'ចុះហត្ថលេខា (VDG)');
  String get signDG => _t('Sign (DG)', 'ចុះហត្ថលេខា (DG)');
  String get archive => _t('Archive', 'រក្សាទុក');
  String get downloadFile => _t('Download File', 'ទាញយកឯកសារ');
  String get viewFile => _t('View File', 'មើលឯកសារ');
  String get viewReport => _t('View Report', 'មើលរបាយការណ៍');

  // ─── DOCUMENT STATUS ───
  String get statusPendingDGInit => _t('Pending DG Review', 'រង់ចាំការត្រួតពិនិត្យ DG');
  String get statusPendingDispatch => _t('Pending Dispatch', 'រង់ចាំការបញ្ជូន');
  String get statusDGDirected => _t('DG Directed', 'DG បានណែនាំ');
  String get statusPendingVDGApproval => _t('Pending VDG Approval', 'រង់ចាំការយល់ព្រម VDG');
  String get statusPendingDGApproval => _t('Pending DG Approval', 'រង់ចាំការយល់ព្រម DG');
  String get statusDGSigned => _t('DG Signed', 'DG បានចុះហត្ថលេខា');
  String get statusArchived => _t('Archived', 'រក្សាទុករួច');
  String get trackingStatus => _t('Tracking Status', 'តាមដានស្ថានភាព');

  // ─── ASSIGN DIALOG ───
  String get assignDepartmentTitle => _t('Assign Department', 'ដាក់ភារៈទៅផ្នែក');
  String get assignDepartmentSubtitle => _t('Select a department and optionally add a note.', 'ជ្រើសរើសផ្នែក ហើយបន្ថែមមតិបន្ថែម (ស្រេចចិត្ត)។');
  String get selectDepartment => _t('Select Department', 'ជ្រើសរើសផ្នែក');
  String get dgNoteOptional => _t('DG Note (Optional)', 'កំណត់ចំណាំ DG (ស្រេចចិត្ត)');
  String get assign => _t('Assign', 'ដាក់ភារៈ');
  String get assignSuccess => _t('Document assigned successfully!', 'ឯកសារត្រូវបានដាក់ភារៈជោគជ័យ!');

  // ─── DISPATCH DIALOG ───
  String get dispatchTitle => _t('Dispatch Document', 'បញ្ជូនឯកសារ');
  String get dispatchSubtitle => _t('Add an optional comment before dispatching.', 'បន្ថែមមតិបន្ថែមមុនពេលបញ្ជូន (ស្រេចចិត្ត)។');
  String get dispatchComment => _t('Dispatch Comment (Optional)', 'មតិការបញ្ជូន (ស្រេចចិត្ត)');
  String get dispatchNow => _t('Dispatch', 'បញ្ជូន');
  String get dispatchSuccess => _t('Document dispatched successfully!', 'ឯកសារត្រូវបានបញ្ជូនជោគជ័យ!');

  // ─── REPORT UPLOAD ───
  String get reportUploadTitle => _t('Upload Report', 'បញ្ចូលរបាយការណ៍');
  String get reportUploadSubtitle => _t('Select a PDF or document file to upload as the department\'s action report.', 'ជ្រើសរើសឯកសារ PDF ឬ Word ដើម្បីបញ្ចូលជារបាយការណ៍ទំនាក់ទំនងផ្នែក។');
  String get selectFile => _t('Select File', 'ជ្រើសរើសឯកសារ');
  String get reportUploadSuccess => _t('Report uploaded successfully!', 'របាយការណ៍ត្រូវបានបញ្ចូលជោគជ័យ!');

  // ─── SIGN ───
  String get signAsVDG => _t('Sign as VDG', 'ចុះហត្ថលេខាជា VDG');
  String get signAsVDGContent => _t('Are you sure you want to sign this document as Vice Director General?', 'តើអ្នកប្រាកដជាចង់ចុះហត្ថលេខាលើឯកសារនេះជា អនុប្រធានក្រុមហ៊ុន?');
  String get signAsVDGSuccess => _t('Document signed by VDG!', 'ឯកសារត្រូវបានចុះហត្ថលេខាដោយ VDG!');
  String get signAsDG => _t('Sign as DG', 'ចុះហត្ថលេខាជា DG');
  String get signAsDGContent => _t('Are you sure you want to sign this document as Director General?', 'តើអ្នកប្រាកដជាចង់ចុះហត្ថលេខាលើឯកសារនេះជា ប្រធានក្រុមហ៊ុន?');
  String get signAsDGSuccess => _t('Document signed by DG!', 'ឯកសារត្រូវបានចុះហត្ថលេខាដោយ DG!');
  String get sign => _t('Sign', 'ចុះហត្ថលេខា');

  // ─── ARCHIVE ───
  String get archiveTitle => _t('Archive Document', 'រក្សាទុកឯកសារ');
  String get archiveContent => _t('Are you sure you want to permanently archive this document?', 'តើអ្នកប្រាកដជាចង់រក្សាទុកឯកសារនេះជាអចិន្ត្រៃយ៍?');
  String get archiveSuccess => _t('Document archived permanently!', 'ឯកសារត្រូវបានរក្សាទុកជាអចិន្ត្រៃយ៍!');
  String get archiveSearch => _t('Archive Search', 'ស្វែងរកបណ្ណសារ');
  String get searchArchive => _t('Search archives...', 'ស្វែងរកក្នុងបណ្ណសារ...');
  String get noArchives => _t('No Archived Documents', 'គ្មានឯកសារបណ្ណសារ');
  String get noArchivesSubtitle => _t('Archived documents will appear here.', 'ឯកសារបណ្ណសារនឹងបង្ហាញនៅទីនេះ។');
  String get searchResults => _t('Search results for', 'លទ្ធផលស្វែងរកសម្រាប់');

  // ─── NOTIFICATIONS ───
  String get notifications => _t('Notifications', 'ការជូនដំណឹង');
  String get markAllRead => _t('Mark all read', 'សម្គាល់ទាំងអស់ថាបានអាន');
  String get noNotifications => _t('No Notifications', 'គ្មានការជូនដំណឹង');
  String get noNotificationsSubtitle => _t('You\'re all caught up!\nCheck back later for updates.', 'អ្នកបានអានទាំងអស់!\nពិនិត្យម្តងទៀតនៅពេលក្រោយ។');
  String get loadingNotifications => _t('Loading notifications...', 'កំពុងផ្ទុកការជូនដំណឹង...');

  // ─── PROFILE ───
  String get profile => _t('Profile', 'ប្រវត្តិរូប');
  String get personalInfo => _t('Personal Information', 'ព័ត៌មានផ្ទាល់ខ្លួន');
  String get settings => _t('Settings', 'ការកំណត់');
  String get userId => _t('User ID', 'លេខសម្គាល់អ្នកប្រើ');
  String get department => _t('Department', 'ផ្នែក');
  String get notAssigned => _t('Not Assigned', 'មិនទាន់ដាក់');
  String get userNotFound => _t('User not found', 'រកមិនឃើញអ្នកប្រើ');
  String get toggleTheme => _t('Toggle Theme', 'ប្តូររូបរាង');
  String get language => _t('Language', 'ភាសា');
  String get languageEnglish => 'English';
  String get languageKhmer => 'ភាសាខ្មែរ';
  String get selectLanguage => _t('Select Language', 'ជ្រើសរើសភាសា');

  // ─── EDIT PROFILE ───
  String get editProfile => _t('Edit Profile', 'កែសម្រួលប្រវត្តិរូប');
  String get editProfileSubtitle => _t('Update your personal information', 'ធ្វើបច្ចុប្បន្នភាពព័ត៌មានផ្ទាល់ខ្លួន');
  String get fullName => _t('Full Name', 'នាមពេញ');
  String get fullNameHint => _t('Enter your full name', 'បញ្ចូលនាមពេញរបស់អ្នក');
  String get changePhoto => _t('Change Photo', 'ផ្លាស់ប្តូររូបថត');
  String get removePhoto => _t('Remove Photo', 'ដកចេញរូបថត');
  String get uploadPhoto => _t('Upload Photo', 'បញ្ចូលរូបថត');
  String get changeAvatar => _t('Change Profile Photo', 'ផ្លាស់ប្តូររូបថតប្រវត្តិរូប');
  String get newPassword => _t('New Password', 'លេខសម្ងាត់ថ្មី');
  String get newPasswordHint => _t('Leave blank to keep current', 'ទទេប្រសិនបើមិនផ្លាស់ប្តូរ');
  String get confirmPassword => _t('Confirm Password', 'បញ្ជាក់លេខសម្ងាត់');
  String get passwordsDoNotMatch => _t('Passwords do not match', 'លេខសម្ងាត់មិនត្រូវគ្នា');
  String get saveChanges => _t('Save Changes', 'រក្សាទុកការផ្លាស់ប្តូរ');
  String get profileUpdated => _t('Profile updated successfully!', 'ប្រវត្តិរូបត្រូវបានធ្វើបច្ចុប្បន្នភាព!');
  String get profileUpdateFailed => _t('Failed to update profile', 'ការធ្វើបច្ចុប្បន្នភាពបានបរាជ័យ');
  String get avatarUpdated => _t('Profile photo updated!', 'រូបថតត្រូវបានធ្វើបច្ចុប្បន្នភាព!');
  String get avatarRemoved => _t('Profile photo removed', 'បានដករូបថតចេញ');
  String get photoOptions => _t('Profile Photo', 'រូបថតប្រវត្តិរូប');
  String get fromGallery => _t('Choose from Gallery', 'ជ្រើសរើសពីវប្ប');
  String get takePhoto => _t('Take a Photo', 'ថតរូបថត');
  String get nameRequired => _t('Name is required', 'ត្រូវការនាម');
  String get invalidEmail => _t('Invalid email address', 'អ៊ីមែលមិនត្រឹមត្រូវ');
  String get savingChanges => _t('Saving...', 'កំពុងរក្សាទុក...');
  String get role => _t('Role', 'តន្ទូរ');
  String get memberSince => _t('Member since', 'ចូលរួមមកតាំងពី');

  // ─── LOGOUT DIALOG ───
  String get logOutTitle => _t('Log Out', 'ចេញពីប្រព័ន្ធ');
  String get logOutContent => _t('Are you sure you want to log out?', 'តើអ្នកប្រាកដជាចង់ចេញពីប្រព័ន្ធ?');

  // ─── COMMON ───
  String get ok => _t('OK', 'យល់ព្រម');
  String get yes => _t('Yes', 'បាទ/ចាស');
  String get no => _t('No', 'ទេ');
  String get save => _t('Save', 'រក្សាទុក');
  String get delete => _t('Delete', 'លុប');
  String get error => _t('Error', 'កំហុស');
  String get success => _t('Success', 'ជោគជ័យ');
  String get retry => _t('Retry', 'ព្យាយាមមួយទៀត');
  String get back => _t('Back', 'ត្រឡប់ក្រោយ');
  String get goBack => _t('Go Back', 'ត្រឡប់ក្រោយ');
  String get accessDenied => _t('Access Denied', 'ការចូលប្រើប្រាស់ត្រូវបានបដិសេធ');
  String get noPermissionUpload => _t('You do not have the required permissions to upload new documents to the system.', 'អ្នកមិនមានសិទ្ធិបញ្ចូលឯកសារថ្មីទៅប្រព័ន្ធ។');
  String get pageNotFound => _t('Page not found', 'រកមិនឃើញទំព័រ');
  String get justNow => _t('Just now', 'ឥឡូវ');
  String get daysAgo => _t('d ago', 'ថ្ងៃមុន');
  String get hoursAgo => _t('h ago', 'ម៉ោងមុន');
  String get minutesAgo => _t('m ago', 'នាទីមុន');
  String get noInternetTitle => _t('No Connection', 'គ្មានការតភ្ជាប់');
  String get filterAll => _t('All', 'ទាំងអស់');
  String get filterPending => _t('Pending', 'រង់ចាំ');
  String get filterInProgress => _t('In Progress', 'កំពុងដំណើរការ');
  String get filterCompleted => _t('Completed', 'រួចរាល់');
  String get tapToSelectFile => _t('Tap to select file', 'ចុចដើម្បីជ្រើសរើសឯកសារ');
  String get resultsFound => _t('results found', 'លទ្ធផលបានរក');
  String get clear => _t('Clear', 'សម្អាត');
  String get accessLevel => _t('Access Level', 'កំរិតចូលប្រើ');
  String get confirmArchive => _t('Confirm Archive', 'បញ្ជាក់ការរក្សាទុក');
  String get confirmSign => _t('Confirm Signature', 'បញ្ជាក់ការចុះហត្ថលេខា');
  String get enterSearchTerm => _t('Please enter a search term', 'សូមបញ្ចូលពាក្យស្វែងរក');
  String get searchFor => _t('Search for', 'ស្វែងរក');
  String get downloadSuccess => _t('Download started!', 'ការទាញយកបានចាប់ផ្តើម!');
  String get downloadFailed => _t('Download failed', 'ការទាញយកបានបរាជ័យ');
  String get documentNotFound => _t('Document not found', 'រកមិនឃើញឯកសារ');
  String get failedToLoad => _t('Failed to load document', 'ផ្ទុកឯកសារបានបរាជ័យ');
  String get chooseFile => _t('Choose File', 'ជ្រើសរើសឯកសារ');
  String get noFileChosen => _t('No file chosen', 'មិនទាន់ជ្រើសរើសឯកសារ');
  String get submit => _t('Submit', 'ដាក់ស្នើ');
  String get uploadNow => _t('Upload', 'បញ្ចូល');

  // ─── STATUS BADGE ───
  String statusLabel(String status) {
    switch (status) {
      case 'pending_dg_init':
        return _t('Pending Review', 'រង់ចាំការត្រួតពិនិត្យ');
      case 'pending_dispatch':
        return _t('Pending Dispatch', 'រង់ចាំការបញ្ជូន');
      case 'dg_directed':
        return _t('DG Directed', 'DG បានណែនាំ');
      case 'pending_vdg_approval':
        return _t('VDG Approval', 'ការយល់ព្រម VDG');
      case 'pending_dg_approval':
        return _t('DG Approval', 'ការយល់ព្រម DG');
      case 'dg_signed':
        return _t('DG Signed', 'DG ចុះហត្ថលេខា');
      case 'completed_archive':
        return _t('Archived', 'បណ្ណសារ');
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'km'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
