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

  /// /// **Assertions:**
  /// - Ensures `horizontalSpacingRatio` is within the range 0.01 and 0.09.
  /// - Ensures that the initial `items` list is not empty.
  /// - If `uiDecorated` is enabled, it checks that `paddingForDecoratedUi`, `titleTextStyle`,
  ///   and `decorationForDecoratedUi` are provided.
  /// /// - If `uiDecorated` is disabled, it checks that `paddingForDecoratedUi` 
  ///   and `decorationForDecoratedUi` are not provided.
  ///
  /// **Returns:**
  const MultiDragAndDrop({
    Key? key,
    required this.items,
    this.itemHeight,
    required this.itemBuilder,
    this.disableTitle = false,
    required this.onListsChanged,
    this.titleTextStyle,
    required  this.uiDecorated,
    this.paddingForDecoratedUi,
    this.titleBoxdecorationForDecoratedUi,
    this.decorationForDecoratedUi,
    this.titleAlignment = TitleAlignment.left,
    this.verticalSpacing = 10,
    this.horizontalSpacingRatio = 0.08,
  })  : assert(horizontalSpacingRatio >= 0.01 && horizontalSpacingRatio < 0.09,
            "Horizontal spacing ratio must be between 0.01 and 0.09"),
        assert(items.length > 0, "items must not be empty"),
        assert(
            uiDecorated == false
                ? (paddingForDecoratedUi == null &&   titleBoxdecorationForDecoratedUi ==null &&
                    decorationForDecoratedUi == null)
                : true,
            "paddingForDecoratedUi, titleBoxdecorationForDecoratedUi and decorationForDecoratedUi must  be null when uiDecorated is false"),
        assert(
            uiDecorated == false ||
                (paddingForDecoratedUi != null &&
                   titleBoxdecorationForDecoratedUi !=null &&
                    decorationForDecoratedUi != null),
            "paddingForDecoratedUi, titleBoxdecorationForDecoratedUi and decorationForDecoratedUi must not be null when UI is decorated"),
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

  /// Builds a draggable and droppable list with dynamic drag-and-drop functionality.
  ///
  /// This method generates the UI for a given index's `DragTarget` list data. It allows
  /// the user to drag items from one list and drop them into another while handling the
  /// drag-and-drop visual feedback and state updates.
  ///
  /// **Parameters:**
  /// - [index]: The index of the current list being rendered.
  /// - [listData]: The data representing the current list, which includes `title` and `items`.
  ///
  /// **Returns:**
  /// A widget representing the draggable and droppable list UI.
  Widget buildList(int index, ListData listData) {
    return Flexible(
      fit: FlexFit
          .tight, // Ensures the widget expands proportionally in a flexible layout.
      child: DragTarget<Map<String, dynamic>>(
        /// Triggered when a dragged item is about to enter this drag target area.
        /// It prevents items from being dragged onto the same index list.
        onWillAcceptWithDetails: (data) =>
            data.data['sourceIndex'] != null &&
            data.data['sourceIndex'] != index,

        /// Triggered when a valid drag item is dropped on this area.
        onAcceptWithDetails: (data) {
          final draggedItem =
              data.data['item']; // Extracts the dragged item data.
          final sourceIndex = data.data[
              'sourceIndex']; // Retrieves the source index of the dragged item.
          onItemDropped(draggedItem, sourceIndex,
              index); // Handles the logic for when an item is dropped.
        },

        /// Main builder logic for rendering the drag target container.
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: widget.uiDecorated
                ? EdgeInsets.only(
                    right: index != widget.items.length - 1
                        ? widget.paddingForDecoratedUi!
                        : 0) // Adds margin only between decorated lists if enabled.
                : const EdgeInsets.all(0),
            decoration: widget.uiDecorated
                ? widget.decorationForDecoratedUi
                : const BoxDecoration(), // Applies custom decoration if `uiDecorated` is true.
            child:
                LayoutBuilder(builder: (context, BoxConstraints constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Renders the draggable list's title section with optional alignment and decoration.
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
                        visible: !widget
                            .disableTitle, // Ensures title visibility is toggleable.
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

                  /// Dynamically generates a scrollable list of draggable items.
                  Expanded(
                    child: ListView.builder(
                      itemCount: listData.items
                          .length, // Dynamically generates the number of list items.
                      itemBuilder: (context, itemIndex) {
                        final item = listData.items[itemIndex];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: widget.verticalSpacing,
                            horizontal: constraints.maxWidth *
                                widget.horizontalSpacingRatio.clamp(0.01, 0.08),
                          ),
                          child: SizedBox(
                            height: widget
                                .itemHeight, // Dynamically sets the height of each item.
                            child: Draggable<Map<String, dynamic>>(
                              data: {
                                'item': item,
                                'sourceIndex': index
                              }, // Passes item and source index on drag.
                              feedback: Opacity(
                                opacity: 0.5,
                                child: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                      width: constraints.maxWidth - 10,
                                      height: widget.itemHeight,
                                      child: buildAnimatedItem(
                                          item)), // Shows item visually when dragged.
                                ),
                              ),
                              onDragStarted: () {
                                // Optionally define actions to perform when drag starts.
                              },
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child: buildAnimatedItem(
                                    item), // Reduces visibility of the dragged item.
                              ),
                              child: buildAnimatedItem(
                                  item), // Displays item in normal state when not dragging.
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