package MT::InstaPost::L10N::ja;

use strict;
use utf8;
use base 'MT::InstaPost::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (
# config.yaml
	'Posts entry from Instagram with the realtime API.' => 'Instagramの写真から、リアルタイムAPIを利用して記事を投稿します。',

# lib/MT/InstaPost/Util.pm
	'Invalid email address to send: [_1]' => '宛先が不明なメールアドレス: [_1]',

# common
	'Instagram Posting' => 'Instagramからの投稿',
	'Client ID' => 'クライアントID',
	'Client Secret' => 'クライアントシークレット',
	'Default Handler' => 'デフォルト投稿方法',
	'Subscription ID' => 'サブスクリプションID',

# tmpl/config.tmpl
	'Redirect URI' => 'リダイレクトURI',
	'This URL does not seem to be reachable from outside. It will get an error. Please change CGIPath in mt-config.cgi to start with http(s).'
		=> 'このURLは外部から到達できないため、Instagramの認証エラーとなります。mt-config.cgi 内の CGIPath 環境変数を http(s)から始まるURLに変更してください。',
	'Create an API client application with this redirect URI at:' => 'まずはこちらのリダイレクトURIでAPIクライアントアプリケーションを作成してください:',
	'Instagram Developer Site' => 'Instagram 開発者向けサイト',
	'This system has already linked with Instagram API.' => 'このシステムは、すでにこのクライアントIDによりInstagram APIとの関連付けがされています。',
	'If you change client id, [_1] user(s) losts Instagram posting linkage.' => 'もしクライアントIDを変更すると、[_1]人のユーザーがInstagram投稿のための認証関係を失います。',
	'Subscription callback Movable Type if authorized user posted Instagram.' => 'サブスクリプションは、認証をしたユーザーがInstagramに投稿をすると、Movable Typeにコールバックを送信します。',

# tmpl/cfg_insta_post.tmpl
	'Instagram Username' => 'Instagramユーザー名',
	'Instagram Posting Settings' => 'Instagramからの投稿設定',
	'Authorized and linked with Instagram account.' => '認証が完了し、Instagramアカウントと関連付けられました。',
	'Instagram subscription not yet set up.' => 'InstagramのAPI連携がまだ設定されていません。',
	'Set Up Subscription' => 'API連携をセットアップする',
	'Please ask to an administrator.' => '管理者にお尋ねください。',
	'Start Authorization' => 'Instagramの認証を開始',
	'Authorize Again' => '再認証',
	'You can authorize again.' => '再度、認証フローを実行することもできます。',
	'Unknown User' => '不明なユーザー',
	'If you want to change, authorize again.' => '変更したい場合は再認証を行ってください。',
	'If you want to switch linked Instagram user, confirm logged out from Instagram at first:'
		=> 'もしInstagramユーザーを変更したい場合は、はじめにInstagramからログアウトしていることを確認してください:',
	'You are already authorized but you configured in another blog or website.' => 'すでにInstagramでの認証は済んでいますが、他のブログまたはウェブサイトで設定されています。',
	'Instagram posts to another blog: ' => 'Instagramへの投稿は他のブログまたはウェブサイトに送信されます: ',
	'Unknown blog' => '不明なブログ',

	'Switch to This Blog or Website' => 'このブログまたはウェブサイトに変更',
	'Or you can authorize to stop posting to [_1], and configure again in this blog or website.' => 'もしくは、[_1]への投稿を停止し、このブログまたはウェブサイトで設定し直すこともできます。',

	'You have never authorized by your Instagram account.' => 'まだInstagramのアカウントで認証を行っていません。',

	'You already linked to Instagram, but API subscription id changed by system administrator and the linkage has lost.'
		=> 'すでにInstagramと接続済みでしたが、システム管理者によりAPIサブスクリプションIDが変更されたため、接続が失われました。',
	'Please authorize again.' => 'もう一度、認証を行って接続してください。',

	'Subscription Handler' => '投稿方法',

	'Stop Linkage' => '連携の停止',
	'If you want to stop Instagram posting, click the following button.' => 'Instagramとの連携を完全に停止する場合は、次のボタンを押してください。',
	'Stop Instagram Linkage' => 'Instagramとの連携を停止',
	'Are you sure to stop Instagram linkage?' => 'Instagramとの連携を停止します。よろしいですか？',
	'Instagram linkage has been stopped.' => 'Instagramとの連携を停止しました',


# system default
	'System Default' => 'システム全体設定に従う',

# tmpl/subscription_handlers/simple_post.tmpl
	'Simple Post' => 'シンプル記事投稿',
	'Setting of Simple Post' => 'シンプル記事投稿の設定',
	'"Simple Post" posts simply an new entry if subscribe Instagram picture.' => '"シンプル記事投稿"は、Instagramの写真の投稿を検知したら新しい記事を投稿します。',
	'Publish Entry' => '記事の公開',
	'Publish at once' => 'すぐに公開する',
	'Save as a draft' => '下書きとして保存する',
 
# email
	'THE FIRST LINE IS SUBJECT' => '1行目は件名として使用',

	'InstaPost Error Email' => 'InstaPostエラーメール',
	'InstaPost Error' => 'InstaPostエラー',
	'InstaPost got an error:' => 'InstaPostの処理中にエラーが発生しました:',
	'The user:' => 'ユーザー:',
	'The data:' => 'データ:',

	'InstaPost Simple Post Email - Confirm' => 'InstaPostシンプル投稿メール(確認)',
	'InstaPost Simple Post Email - Complete' => 'InstaPostシンプル投稿メール(完了)',

	'Confirmation of a new entry from Instagram' => 'Instagramからの新しい記事の確認',
	'A new entry created as draft from your Instagram.' => 'Instagramから新しい記事が下書きとして作成されました。',
	'To publish, to edit or to delete the entry:' => '記事を公開、編集、または削除するには:',
	'The Instagram picture:' => 'Instagramの写真:',
	'To change Instagram linkage settings:' => 'Instagramとの連携設定を変更するには:',

	'A new entry published from Instagram' => 'Instagramから新しい記事が公開されました',
	'To open the entry:' => '記事を表示するには:',
	'To edit or to delete the entry:' => '記事を編集または削除するには:',

# Error messages
	'Bad format JSON: [_1]: [_2]' => '不正なフォーマットのJSONデータです: [_1]: [_2]',
	'The JSON has unexpected type. Expected [_1] but [_2]: [_3]' => '予期しない形式のJSONデータです。必要な形式は[_1]ですが、実際のデータは[_2]です: [_3]',
	'API request to create subscription failed: [_1]. [_2]' => 'サブスクリプションを作成するためのAPI呼び出しに失敗しました: [_1]. [_2]',
	'API response is not JSON format.: Resposne code is [_1].' => 'APIの戻り値がJSONフォーマットではありません: レスポンスコード: [_1]',
	'API resposne seems good, but cant not get subscription Id: [_1]' => 'APIの戻り値に異常はありませんが、サブスクリプションIDを取得できません: [_1]',
	'API request to get media failed: [_1]. [_2]' => 'メディア情報の取得APIの呼び出しに失敗しました: [_1]: [_2]',
	'API response is not JSON format.: Resposne code is [_1]: [_2].' => 'APIの戻り値がJSONフォーマットではありません。レスポンスコード: [_1]: [_2]',
	'Cannot get access_token: [_1]' => 'アクセストークンが取得できません: [_1]',
	'Cannot get user information: [_1]' => 'ユーザー情報が取得できません: [_1]',
	'Cannot get user id: [_1]' => 'ユーザーIDが取得できません: [_1]',
	'Cannot get user name: [_1]' => 'ユーザー名が取得できません: [_1]',
);

1;

