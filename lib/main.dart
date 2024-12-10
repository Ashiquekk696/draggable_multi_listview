import 'package:flutter/material.dart';

/// A model that represents a list with a title and items.
/// It holds the following:
/// - [title]: The title of the list.
/// - [items]: A list of dynamic items contained within the list.
class ListData {
  /// Title of the list.
  final String title;

  /// Items within the list.
  final List<dynamic> items;

  /// Constructor for creating a ListData object.
  ListData({required this.title, required this.items});
}

/// An enumeration to define alignment for the list titles.
enum TitleAlignment {
  /// Align title to the left.
  left,

  /// Align title to the right.
  right,

  /// Center-align the title.
  center,
}

/// A widget to create multiple lists with drag-and-drop functionality.
/// Allows the user to move items between lists and provides a callback
/// when lists are updated.
class MultiDragAndDrop extends StatefulWidget {
  /// A list of [ListData] objects representing the initial lists.
  /// Each list includes a title and a list of items.
  /// Must not be empty.
  final List<ListData> items;

  /// A builder function to create widgets for each item.
  /// Accepts an item of dynamic type.
  final Widget Function(dynamic item) itemBuilder;

  /// Spacing ratio for horizontal gaps between list items.
  /// Must be in the range of 0.01 to 0.09.
  final double horizontalSpacingRatio;

  /// Vertical spacing between items in the lists.
  final double verticalSpacing;

  /// Whether to hide the title of each list.
  final bool disableTitle;

  /// Padding for decorated UI if [uiDecorated] is true.
  final double? paddingForDecoratedUi;

  /// Decoration for each list container if [uiDecorated] is true.
  /// Cannot be null when [uiDecorated] is true.
  final BoxDecoration? decorationForDecoratedUi;

  /// Decoration for the title box when [uiDecorated] is true.
  final BoxDecoration? titleBoxdecorationForDecoratedUi;

  /// Enables custom UI decorations for the lists.
  final bool uiDecorated;

  /// Custom text style for the list titles.
  final TextStyle? titleTextStyle;

  /// Alignment of the list titles.
  final TitleAlignment titleAlignment;

  /// Height of each list item.
  final double? itemHeight;

  /// A callback function triggered when items are moved between lists.
  /// Provides the updated lists, source index, target index, and the moved item.
  final void Function(
    List<ListData> updatedLists,
    int sourceIndex,
    int targetIndex,
    dynamic movedItem,
  ) onListsChanged;

  /// Constructor for creating the MultiDragAndDrop widget.
  const MultiDragAndDrop({
    Key? key,
    required this.items,
    this.itemHeight,
    required this.itemBuilder,
    required this.disableTitle,
    required this.onListsChanged,
    this.titleTextStyle,
    this.uiDecorated = false,
    this.paddingForDecoratedUi,
    this.titleBoxdecorationForDecoratedUi,
    this.decorationForDecoratedUi,
    this.titleAlignment = TitleAlignment.left,
    this.verticalSpacing = 10,
    this.horizontalSpacingRatio = 0.08,
  })  : assert(horizontalSpacingRatio >= 0.01 && horizontalSpacingRatio < 0.09,
            "Horizontal spacing ratio must be between 0.01 and 0.09"),
        assert(items.length > 0, "Initial lists must not be empty"),
        assert(
            uiDecorated == false ||
                (paddingForDecoratedUi != null &&
                    titleTextStyle != null &&
                    decorationForDecoratedUi != null),
            "Padding, text style, and decoration must not be null when UI is decorated"),
        super(key: key);

  @override
  State<MultiDragAndDrop> createState() => _MultiDragAndDropState();
}

class _MultiDragAndDropState extends State<MultiDragAndDrop>
    with TickerProviderStateMixin {
  /// Local copy of the lists.
  late List<ListData> lists;

  /// Animation controllers for fade-in and fade-out effects for each item.
  final Map<dynamic, AnimationController> _fadeControllers = {};

  @override
  void initState() {
    super.initState();
    lists = widget.items;

    /// Initialize fade controllers for all items in all lists.
    for (var list in lists) {
      for (var item in list.items) {
        _fadeControllers[item] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..forward();
      }
    }
  }

  @override
  void dispose() {
    /// Dispose of all animation controllers to free resources.
    for (var controller in _fadeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Handles the dropping of an item from one list to another.
  void onItemDropped(dynamic item, int sourceIndex, int targetIndex) {
    setState(() {
      lists[sourceIndex].items.remove(item);
      lists[targetIndex].items.add(item);
    });

    widget.onListsChanged(
      lists,
      sourceIndex,
      targetIndex,
      item,
    );
  }

  /// Builds a draggable item with animation.
  Widget buildAnimatedItem(dynamic item) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeControllers[item]!,
          curve: Curves.easeInOut,
        ),
      ),
      child: FadeTransition(
        opacity: _fadeControllers[item]!,
        child: widget.itemBuilder(item),
      ),
    );
  }

  /// Builds a single list with drag-and-drop functionality.
  Widget buildList(int index, ListData listData) {
    return Flexible(
      fit: FlexFit.tight,
      child: DragTarget<Map<String, dynamic>>(
        onWillAcceptWithDetails: (data) =>
            data.data['sourceIndex'] != null &&
            data.data['sourceIndex'] != index,
        onAcceptWithDetails: (data) {
          final draggedItem = data.data['item'];
          final sourceIndex = data.data['sourceIndex'];
          onItemDropped(draggedItem, sourceIndex, index);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: widget.uiDecorated
                ? EdgeInsets.only(
                    right: index != widget.items.length - 1
                        ? widget.paddingForDecoratedUi!
                        : 0)
                : const EdgeInsets.all(0),
            decoration: widget.uiDecorated
                ? widget.decorationForDecoratedUi
                : const BoxDecoration(),
            child:
                LayoutBuilder(builder: (context, BoxConstraints constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title box with optional decoration and alignment.
                  Container(
                    width: constraints.maxWidth,
                    decoration: widget.titleBoxdecorationForDecoratedUi,
                    child: Align(
                      alignment: widget.titleAlignment == TitleAlignment.left
                          ? Alignment.centerLeft
                          : widget.titleAlignment == TitleAlignment.right
                              ? Alignment.centerRight
                              : Alignment.center,
                      child: Visibility(
                        visible: !widget.disableTitle,
                        child: Text(
                          listData.title,
                          style: widget.titleTextStyle ??
                              const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  /// List of items with spacing and drag-and-drop functionality.
                  Expanded(
                    child: ListView.builder(
                      itemCount: listData.items.length,
                      itemBuilder: (context, itemIndex) {
                        final item = listData.items[itemIndex];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: widget.verticalSpacing,
                            horizontal: constraints.maxWidth *
                                widget.horizontalSpacingRatio.clamp(0.01, 0.08),
                          ),
                          child: SizedBox(
                            height: widget.itemHeight,
                            child: Draggable<Map<String, dynamic>>(
                              data: {'item': item, 'sourceIndex': index},
                              feedback: Opacity(
                                opacity: 0.5,
                                child: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                      width: constraints.maxWidth - 10,
                                      height: widget.itemHeight,
                                      child: buildAnimatedItem(item)),
                                ),
                              ),
                              onDragStarted: (){
                                
                              },
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child: buildAnimatedItem(item),
                              ),
                              child: buildAnimatedItem(item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        lists.length,
        (index) {
          return buildList(
              index, lists[index]); // Pass ListData object to buildList
        },
      ),
    );
  }
}

void main() {
  runApp(DragDropExample());
} 
/// A StatelessWidget representing the entire example UI for a
/// Drag-and-Drop task manager with three categories: To-Do, In Progress, Completed.
class DragDropExample extends StatelessWidget {
  DragDropExample({super.key});

  /// List of tasks in the "In Progress" state.
  /// Each task contains a title, description, and due date.
  final List<Map> inProgress = [
    {
      "title": "Write unit tests",
      "description": "Add test coverage for the user authentication module",
      "dueDate": "2024-12-04",
    },
    {
      "title": "Update documentation",
      "description": "Revise API documentation for the latest endpoints",
      "dueDate": "2024-12-07",
    },
  ];

  /// List of tasks in the "Completed" state.
  /// Each task contains a title, description, and due date.
  final List<Map> completed = [
    {
      "title": "Fix login bug",
      "description": "Resolved issue where login failed for new users",
      "dueDate": "2024-12-01",
    },
    {
      "title": "Team meeting",
      "description": "Discussed project progress and assigned new tasks",
      "dueDate": "2024-12-02",
    },
  ];

  /// List of tasks in the "To-Do" state.
  /// Each task contains a title, description, and due date.
  final List<Map> toDo = [
    {
      "title": "Complete Flutter project",
      "description": "Work on the main page layout and implement navigation",
      "dueDate": "2024-12-05",
    },
    {
      "title": "Review PRs",
      "description": "Go through pending pull requests and leave comments",
      "dueDate": "2024-12-06",
    },
    {
      "title": "Prepare presentation",
      "description": "Create slides for the upcoming sprint demo",
      "dueDate": "2024-12-08",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disables the debug banner in the app
      title: 'Drag and Drop Example', // Sets the app's title
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF3F8FB), // Background color of the entire app
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF004D40), // AppBar's background color
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task Manager'), // Title of the AppBar
        ),
        body: Padding(
          padding: const EdgeInsets.all(10), // Adds padding around the body
          child: MultiDragAndDrop(
            disableTitle: false, // Enables the title for drag-and-drop functionality
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ), // Customizes the title text style
            uiDecorated: true, // Enables UI decorations for the drag-and-drop lists
            verticalSpacing: 5, // Spacing between lists vertically
            paddingForDecoratedUi: 15, // Padding added around the UI components
            titleBoxdecorationForDecoratedUi: const BoxDecoration(
              color: Color(0xFF004D40),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ), // UI decoration style for list titles
            decorationForDecoratedUi: BoxDecoration(
              color: Colors.teal[50], // Background color for the drag-and-drop UI
              borderRadius: const BorderRadius.all(Radius.circular(20)), // Rounds the corners of the boxes
              border: Border.all(color: Colors.teal, width: 1.5), // Adds a teal border
            ),
            titleAlignment: TitleAlignment.center, // Centers the titles
            items: [
              ListData(title: 'To-Do', items: toDo), // "To-Do" list with its respective tasks
              ListData(title: 'In Progress', items: inProgress), // "In Progress" list with its respective tasks
              ListData(title: 'Completed', items: completed), // "Completed" list with its respective tasks
            ],
            horizontalSpacingRatio: 0.02, // Spacing ratio between items horizontally
            itemBuilder: (item) => Container(
              decoration: BoxDecoration(
                color: Colors.white, // Sets item background color
                borderRadius: BorderRadius.circular(12), // Adds rounded corners to items
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0), // Padding inside the draggable task items
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'].toString(), // Displays the title of the item
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(height: 8), 
                    Text(
                      item['description'].toString(), // Displays the description of the item
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Due: ${item['dueDate']}", // Displays the due date
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onListsChanged: (updatedLists, sourceIndex, targetIndex, movedItem) {
              // Handle drag-and-drop events
              print('Lists updated');
              print('Updated lists: $updatedLists');
              print('Source Index: $sourceIndex');
              print('Target Index: $targetIndex');
              print('Moved item: $movedItem from $sourceIndex to $targetIndex');
            },
          ),
        ),
      ),
    );
  }
}
