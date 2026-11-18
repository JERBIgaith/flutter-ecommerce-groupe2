import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/comment_controller.dart';
import '../../models/comment_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

/// Admin screen to view and moderate (delete) comments for a product
class AdminProductCommentsScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const AdminProductCommentsScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<AdminProductCommentsScreen> createState() =>
      _AdminProductCommentsScreenState();
}

class _AdminProductCommentsScreenState
    extends State<AdminProductCommentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentController>().listenToComments(widget.productId);
    });
  }

  Future<void> _handleAdminDeleteComment(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Comment'),
        content: Text(
          'Delete comment by "${comment.userName}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final commentController = context.read<CommentController>();
      final success = await commentController.deleteComment(
        productId: widget.productId,
        commentId: comment.id,
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted by admin'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              commentController.errorMessage ?? 'Failed to delete comment',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentController = context.watch<CommentController>();
    final comments = commentController.comments;

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments: ${widget.productName}'),
      ),
      body: commentController.isLoading && comments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : comments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No comments for this product',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final initial = comment.userName.isNotEmpty
                        ? comment.userName[0].toUpperCase()
                        : 'U';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (comment.isEdited) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '(edited)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    formatDateTime(comment.createdAt),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    comment.text,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              tooltip: 'Delete comment',
                              onPressed: () =>
                                  _handleAdminDeleteComment(comment),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
