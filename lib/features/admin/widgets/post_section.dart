import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import 'post_list_item.dart';
import 'pagination_controls.dart';

class PostSection extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final Set<int> selectedPostIds;
  final int postPage;
  final int totalPosts;
  final String postQuery;
  final Function(String) onSearch;
  final VoidCallback onAdd;
  final Function(Post?) onEdit;
  final Function(List<int>) onDelete;
  final Function(int) onPageChanged;
  final Function(bool?, int) onToggleSelect;
  final Function(bool?) onToggleSelectAll;

  const PostSection({
    super.key,
    required this.posts,
    required this.isLoading,
    required this.selectedPostIds,
    required this.postPage,
    required this.totalPosts,
    required this.postQuery,
    required this.onSearch,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onPageChanged,
    required this.onToggleSelect,
    required this.onToggleSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Manage Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Post'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: onSearch,
          onSubmitted: (_) => onPageChanged(1),
          decoration: const InputDecoration(
            labelText: 'Search Posts',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        isLoading
            ? const CircularProgressIndicator()
            : Column(
                children: [
                  if (posts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selectedPostIds.length == posts.length && posts.isNotEmpty,
                            onChanged: onToggleSelectAll,
                          ),
                          const Text('Select All'),
                          const Spacer(),
                          if (selectedPostIds.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => onDelete(selectedPostIds.toList()),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: Text('Delete Selected (${selectedPostIds.length})'),
                              style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return PostListItem(
                        post: post,
                        isSelected: selectedPostIds.contains(post.id),
                        onToggleSelect: (value) => onToggleSelect(value, post.id),
                        onEdit: () => onEdit(post),
                        onDelete: () => onDelete([post.id]),
                      );
                    },
                  ),
                  PaginationControls(
                    currentPage: postPage,
                    totalCount: totalPosts,
                    onPageChanged: onPageChanged,
                  ),
                ],
              ),
      ],
    );
  }
}
