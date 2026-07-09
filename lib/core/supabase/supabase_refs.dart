/// Single source of truth for Supabase table / RPC / bucket / channel names.
class Tables {
  Tables._();
  static const profiles = 'profiles';
  static const conversations = 'conversations';
  static const participants = 'conversation_participants';
  static const messages = 'messages';
  static const reactions = 'message_reactions';
  static const callLogs = 'call_logs';
  static const stories = 'stories';
  static const storyViews = 'story_views';
  static const storyLikes = 'story_likes';
  static const storyComments = 'story_comments';
  static const friendships = 'friendships';
  static const userBlocks = 'user_blocks';
  static const notifications = 'notifications';
  static const gameMatches = 'game_matches';
  static const gameRpsChoices = 'game_rps_choices';
  static const posts = 'posts';
  static const postLikes = 'post_likes';
  static const postComments = 'post_comments';
}

class Rpcs {
  Rpcs._();
  static const getOrCreateConversation = 'get_or_create_conversation';
  static const markConversationRead = 'mark_conversation_read';
  static const searchUsers = 'search_users';
  static const deleteConversation = 'delete_conversation';
  static const hideMessageForMe = 'hide_message_for_me';
  static const deleteMessageForEveryone = 'delete_message_for_everyone';
  static const relationshipWith = 'relationship_with';
  static const sendFriendRequest = 'send_friend_request';
  static const acceptFriendRequest = 'accept_friend_request';
  static const blockUser = 'block_user';
  static const unblockUser = 'unblock_user';
  static const createMatch = 'create_match';
  static const gameMove = 'game_move';
  static const abandonMatch = 'abandon_match';
}

class Buckets {
  Buckets._();
  static const avatars = 'avatars';
  static const chatMedia = 'chat-media';
  static const voiceNotes = 'voice-notes';
  static const stories = 'stories';
  static const posts = 'posts';
}
