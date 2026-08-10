import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/core/navigation/app_destination.dart';

class AppTranslation {
  final String code; // 'en' or 'fr'

  const AppTranslation(this.code);

  bool get isFr => code == 'fr';

  // Navigation & General
  String get dashboard => isFr ? 'Tableau de bord' : 'Dashboard';
  String get projects => isFr ? 'Projets' : 'Projects';
  String get tasks => isFr ? 'Tâches' : 'Tasks';
  String get notes => isFr ? 'Notes' : 'Notes';
  String get calendar => isFr ? 'Calendrier' : 'Calendar';
  String get canvas => isFr ? 'Canva' : 'Canvas';
  String get settings => isFr ? 'Paramètres' : 'Settings';
  String get focusMode => isFr ? 'Mode Focus' : 'Focus Mode';
  String get workspace => isFr ? 'Espace de travail' : 'Workspace';

  // Quick Capture / Focus Bar
  String get nextFocusPlaceholder =>
      isFr ? 'Quel est votre prochain objectif ?' : 'What is your next focus?';
  String get quickCapture => isFr ? 'SAISIE RAPIDE' : 'QUICK CAPTURE';
  String get fleetingThoughts => isFr
      ? 'Toutes vos pensées spontanées, indépendantes des projets.'
      : 'All your fleeting thoughts, unattached to any project.';

  // Tasks Screen
  String get taskManagement => isFr ? 'GESTION DES TÂCHES' : 'TASK MANAGEMENT';
  String get streamlinedWorkflow => isFr
      ? 'Flux de travail fluide inspiré de Linear et Todoist.'
      : 'Streamlined workflow inspired by Linear & Todoist.';
  String get allTasks => isFr ? 'Toutes' : 'All Tasks';
  String get toDo => isFr ? 'À faire' : 'To Do';
  String get inProgress => isFr ? 'En cours' : 'In Progress';
  String get completed => isFr ? 'Terminées' : 'Completed';
  String get newTask => isFr ? '+ Nouvelle tâche' : '+ New Task';
  String get searchTasks => isFr ? 'Rechercher des tâches...' : 'Search tasks...';
  String get listView => isFr ? 'Liste' : 'List';
  String get boardView => isFr ? 'Tableau' : 'Board';
  String get priorityHigh => isFr ? 'Haute' : 'High';
  String get priorityMedium => isFr ? 'Moyenne' : 'Medium';
  String get priorityLow => isFr ? 'Basse' : 'Low';
  String get noTasks => isFr ? 'Aucune tâche trouvée' : 'No tasks found';
  String get noTasksSubtitle => isFr
      ? 'Commencez par créer votre première tâche.'
      : 'Get started by creating your first task.';

  // Notes Screen
  String get newNote => isFr ? '+ Nouvelle note' : '+ New Note';
  String get searchNotes => isFr ? 'Rechercher des notes...' : 'Search notes...';
  String get deleteNote => isFr ? 'Supprimer la note ?' : 'Delete note?';
  String get deleteNoteConfirm => isFr
      ? 'Cette note sera supprimée définitivement.'
      : 'This note will be permanently deleted.';
  String get blankCanvas => isFr ? 'Une toile vierge vous attend' : 'A blank canvas awaits';
  String get blankCanvasSubtitle => isFr
      ? 'Cliquez sur le bouton + Nouvelle note pour consigner votre première idée.'
      : 'Click the + New Note button to capture your first thought.';
  String get untitledNote => isFr ? 'Note sans titre' : 'Untitled Note';
  String get cancel => isFr ? 'Annuler' : 'Cancel';
  String get delete => isFr ? 'Supprimer' : 'Delete';
  String get save => isFr ? 'Enregistrer' : 'Save';
  String get create => isFr ? 'Créer' : 'Create';

  // Projects Screen
  String get projectsHeader => isFr ? 'PROJETS' : 'PROJECTS';
  String get createProject => isFr ? 'CRÉER UN PROJET' : 'CREATE PROJECT';
  String get newProject => isFr ? 'NOUVEAU PROJET' : 'NEW PROJECT';
  String get editProject => isFr ? 'MODIFIER LE PROJET' : 'EDIT PROJECT';
  String get projectTitle => isFr ? 'Titre du projet' : 'Project Title';
  String get description => isFr ? 'Description' : 'Description';
  String get deadline => isFr ? 'Date limite' : 'Deadline';
  String get noProjects => isFr ? 'Aucun projet dans cet espace de travail' : 'No projects in this workspace';
  String get noProjectsSubtitle => isFr
      ? 'Créez votre premier projet pour commencer'
      : 'Create your first project to get started';

  // Calendar Screen
  String get calendarHeader => isFr ? 'CALENDRIER' : 'CALENDAR';
  String get today => isFr ? "Aujourd'hui" : 'Today';
  String get noEvents => isFr ? 'Aucun événement pour ce jour' : 'No events for this day';

  // Settings Screen
  String get configuration => isFr ? 'Configuration' : 'Configuration';
  String get appearance => isFr ? 'APPARENCE' : 'APPEARANCE';
  String get language => isFr ? 'LANGUE' : 'LANGUAGE';
  String get languageSelectTitle => isFr ? 'Langue de l\'application' : 'Application Language';
  String get languageSelectSubtitle => isFr
      ? 'Basculez entre le Français et l\'Anglais'
      : 'Switch between English and French';
  String get english => isFr ? 'English 🇬🇧' : 'English 🇬🇧';
  String get french => isFr ? 'Français 🇫🇷' : 'Français 🇫🇷';
  String get darkMode => isFr ? 'Mode Sombre' : 'Dark Mode';
  String get darkModeSubtitle => isFr
      ? 'Thème sombre élégant, agréable pour les yeux'
      : 'Warm charcoal theme, easy on the eyes';
  String get sidebarExtended => isFr ? 'Barre latérale étendue' : 'Sidebar Extended';
  String get sidebarExtendedSubtitle => isFr
      ? 'Afficher la barre latérale avec libellés'
      : 'Show full sidebar with labels';
  String get prismaticBorders => isFr ? 'Bordures Prismatiques' : 'Prismatic Borders';
  String get notifications => isFr ? 'Notifications' : 'Notifications';
  String get behavior => isFr ? 'COMPORTEMENT' : 'BEHAVIOR';
  String get navigation => isFr ? 'NAVIGATION' : 'NAVIGATION';
  String get dataManagement => isFr ? 'GESTION DES DONNÉES' : 'DATA MANAGEMENT';
  String get shortcuts => isFr ? 'RACCOURCIS' : 'SHORTCUTS';
  String get about => isFr ? 'À PROPOS' : 'ABOUT';

  String getDestinationLabel(AppDestination dest) {
    switch (dest) {
      case AppDestination.dashboard:
        return dashboard;
      case AppDestination.projects:
        return projects;
      case AppDestination.tasks:
        return tasks;
      case AppDestination.notes:
        return notes;
      case AppDestination.calendar:
        return calendar;
      case AppDestination.analytics:
        return isFr ? 'Analytique' : 'Analytics';
      case AppDestination.settings:
        return settings;
    }
  }
}

final translationProvider = Provider<AppTranslation>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return AppTranslation(prefs.language);
});
