<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/**
 * FishTrackPro API (v1)
 *
 * Базовые соглашения:
 * - Все ресурсы — JSON.
 * - Время — ISO8601 UTC.
 * - Пагинация: ?page=1&per_page=20 (по умолчанию 20, max 100).
 * - Флаговые фичи берутся из config('feature.*'), всегда безопасно отключаемые.
 *
 * Важно: web.php и api.php подключаются отдельно. Здесь — только API.
 */

/* ----------------------------------------
|  Здоровье/метаданные (без авторизации)
|-----------------------------------------*/
Route::get('/health', fn () => response()->json(['status' => 'ok', 'ts' => now()->toIso8601String()]));
Route::get('/version', fn () => response()->json(['api' => 'v1', 'commit' => config('app.commit_hash', 'dev')]));

/* ----------------------------------------
|  Версионирование v1
|-----------------------------------------*/
Route::prefix('v1')->group(function () {

    /* ----------------------------------------
    |  Auth (регистрация/логин/соц/refresh/password)
    |-----------------------------------------*/
    Route::prefix('auth')->group(function () {
        Route::post('register', [\App\Http\Controllers\Api\AuthController::class, 'register']);
        Route::post('login',    [\App\Http\Controllers\Api\AuthController::class, 'login']);
        Route::post('logout',   [\App\Http\Controllers\Api\AuthController::class, 'logout'])->middleware('auth:sanctum');
        Route::post('refresh',  [\App\Http\Controllers\Api\AuthController::class, 'refresh']); // если JWT
        Route::post('password/forgot', [\App\Http\Controllers\Api\AuthController::class, 'forgot']);
        Route::post('password/reset',  [\App\Http\Controllers\Api\AuthController::class, 'reset']);
        // OAuth провайдеры (по фиче)
        if (config('feature.oauth_google')) {
            Route::post('oauth/google', [\App\Http\Controllers\Api\AuthController::class, 'oauthGoogle']);
        }
        if (config('feature.oauth_apple')) {
            Route::post('oauth/apple', [\App\Http\Controllers\Api\AuthController::class, 'oauthApple']);
        }
    });

    /* ----------------------------------------
    |  Профиль/пользователи
    |-----------------------------------------*/
    Route::middleware('auth:sanctum')->prefix('me')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\UsersController::class, 'me']);
        Route::put('/', [\App\Http\Controllers\Api\UsersController::class, 'update']);
        Route::post('avatar', [\App\Http\Controllers\Api\UsersController::class, 'uploadAvatar']);
        Route::get('settings', [\App\Http\Controllers\Api\UsersController::class, 'settings']);
        Route::put('settings', [\App\Http\Controllers\Api\UsersController::class, 'updateSettings']);
        Route::get('achievements', [\App\Http\Controllers\Api\AchievementsController::class, 'myAchievements']);
        Route::get('subscriptions', [\App\Http\Controllers\Api\BillingController::class, 'mySubscriptions']);
    });
    Route::get('users/{id}', [\App\Http\Controllers\Api\UsersController::class, 'show'])->whereNumber('id');
    Route::get('users/{id}/stats', [\App\Http\Controllers\Api\UsersController::class, 'stats'])->whereNumber('id');

    /* ----------------------------------------
    |  Карта / точки (Map)
    |-----------------------------------------*/
    if (config('feature.map', true)) {
        Route::prefix('map')->group(function () {
            // Общедоступные (для неавторизованных видны лишь краткие карточки)
            Route::get('points', [\App\Http\Controllers\Api\MapController::class, 'index']);            // ?bbox=...&filter=...
            Route::get('points/{id}', [\App\Http\Controllers\Api\MapController::class, 'show'])->whereNumber('id');

            // Авторизованные операции
            Route::middleware('auth:sanctum')->group(function () {
                Route::post('points', [\App\Http\Controllers\Api\MapController::class, 'store']);       // модерация
                Route::put('points/{id}', [\App\Http\Controllers\Api\MapController::class, 'update'])->whereNumber('id');
                Route::delete('points/{id}', [\App\Http\Controllers\Api\MapController::class, 'destroy'])->whereNumber('id');
                Route::post('points/{id}/share', [\App\Http\Controllers\Api\MapController::class, 'share'])->whereNumber('id');
                Route::post('points/{id}/highlight', [\App\Http\Controllers\Api\PaymentsController::class, 'highlightPoint'])->whereNumber('id');
                Route::post('favorites/{id}', [\App\Http\Controllers\Api\FavoritesController::class, 'togglePoint'])->whereNumber('id');
                // AR-поиск прошлых мест (возвращает ориентиры/векторные подсказки)
                if (config('feature.ar_mode', true)) {
                    Route::get('ar/visits', [\App\Http\Controllers\Api\ARController::class, 'visits']);
                }
            });

            // Списки/категории/фильтры
            Route::get('categories', [\App\Http\Controllers\Api\MapController::class, 'categories']);    // магазины, слипы, турбазы, уловы
            Route::get('list',       [\App\Http\Controllers\Api\MapController::class, 'list']);          // страница полного списка мест
        });
    }

    /* ----------------------------------------
    |  Уловы (Catches)
    |-----------------------------------------*/
    Route::prefix('catches')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\CatchesController::class, 'index']); // публичные по приватности
        Route::get('{id}', [\App\Http\Controllers\Api\CatchesController::class, 'show'])->whereNumber('id');

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('/', [\App\Http\Controllers\Api\CatchesController::class, 'store']); // AI распознавание рыбы + погода
            Route::put('{id}', [\App\Http\Controllers\Api\CatchesController::class, 'update'])->whereNumber('id');
            Route::delete('{id}', [\App\Http\Controllers\Api\CatchesController::class, 'destroy'])->whereNumber('id');

            // Лайки/комменты/репосты
            Route::post('{id}/like',    [\App\Http\Controllers\Api\ReactionsController::class, 'like'])->whereNumber('id');
            Route::post('{id}/unlike',  [\App\Http\Controllers\Api\ReactionsController::class, 'unlike'])->whereNumber('id');
            Route::get('{id}/comments', [\App\Http\Controllers\Api\CommentsController::class, 'index'])->whereNumber('id');
            Route::post('{id}/comments',[\App\Http\Controllers\Api\CommentsController::class, 'store'])->whereNumber('id');
            Route::post('{id}/repost',  [\App\Http\Controllers\Api\ShareController::class, 'repost'])->whereNumber('id');

            // Медиа
            Route::post('{id}/media',   [\App\Http\Controllers\Api\MediaController::class, 'uploadForCatch'])->whereNumber('id');
        });
    });

    /* ----------------------------------------
    |  Лента (Global/Local/Follow)
    |-----------------------------------------*/
    if (config('feature.feed', true)) {
        Route::prefix('feed')->group(function () {
            Route::get('global', [\App\Http\Controllers\Api\FeedController::class, 'global']);
            Route::get('local',  [\App\Http\Controllers\Api\FeedController::class, 'local']);  // ?lat=&lng=
            Route::middleware('auth:sanctum')->get('follow', [\App\Http\Controllers\Api\FeedController::class, 'follow']);
        });
    }

    /* ----------------------------------------
    |  Уведомления (центр)
    |-----------------------------------------*/
    Route::middleware('auth:sanctum')->prefix('notifications')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\NotificationsController::class, 'index']); // фильтры: type, is_read
        Route::post('read-all', [\App\Http\Controllers\Api\NotificationsController::class, 'readAll']);
        Route::post('{id}/read', [\App\Http\Controllers\Api\NotificationsController::class, 'markRead'])->whereNumber('id');
        Route::delete('{id}', [\App\Http\Controllers\Api\NotificationsController::class, 'destroy'])->whereNumber('id');
        Route::post('subscribe', [\App\Http\Controllers\Api\NotificationsController::class, 'subscribePush']); // FCM token
        Route::post('email/subscribe', [\App\Http\Controllers\Api\NotificationsController::class, 'subscribeEmail']);
    });

    /* ----------------------------------------
    |  Друзья / Подписки / Чаты
    |-----------------------------------------*/
    Route::middleware('auth:sanctum')->group(function () {
        // друзья/фолловинг
        Route::get('friends', [\App\Http\Controllers\Api\FriendsController::class, 'index']);
        Route::post('friends/{id}/request', [\App\Http\Controllers\Api\FriendsController::class, 'request'])->whereNumber('id');
        Route::post('friends/{id}/accept',  [\App\Http\Controllers\Api\FriendsController::class, 'accept'])->whereNumber('id');
        Route::post('friends/{id}/remove',  [\App\Http\Controllers\Api\FriendsController::class, 'remove'])->whereNumber('id');

        Route::post('follow/{id}',   [\App\Http\Controllers\Api\FollowController::class, 'follow'])->whereNumber('id');
        Route::post('unfollow/{id}', [\App\Http\Controllers\Api\FollowController::class, 'unfollow'])->whereNumber('id');

        // чаты (личные/групповые)
        Route::prefix('chats')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\ChatsController::class, 'list']);
            Route::post('/', [\App\Http\Controllers\Api\ChatsController::class, 'create']);
            Route::get('{id}', [\App\Http\Controllers\Api\ChatsController::class, 'show'])->whereNumber('id');
            Route::post('{id}/messages', [\App\Http\Controllers\Api\ChatsController::class, 'send'])->whereNumber('id');
            Route::get('{id}/messages',  [\App\Http\Controllers\Api\ChatsController::class, 'messages'])->whereNumber('id');
            Route::post('{id}/members',  [\App\Http\Controllers\Api\ChatsController::class, 'addMember'])->whereNumber('id');
            Route::delete('{id}/members/{userId}', [\App\Http\Controllers\Api\ChatsController::class, 'removeMember'])->whereNumber('id','userId');
        });
    });

    /* ----------------------------------------
    |  Клубы / Команды
    |-----------------------------------------*/
    if (config('feature.clubs', true)) {
        Route::prefix('clubs')->group(function () {
            Route::get('/',   [\App\Http\Controllers\Api\ClubsController::class, 'index']);
            Route::get('{id}',[\App\Http\Controllers\Api\ClubsController::class, 'show'])->whereNumber('id');

            Route::middleware('auth:sanctum')->group(function () {
                Route::post('/', [\App\Http\Controllers\Api\ClubsController::class, 'store']);
                Route::put('{id}', [\App\Http\Controllers\Api\ClubsController::class, 'update'])->whereNumber('id');
                Route::delete('{id}', [\App\Http\Controllers\Api\ClubsController::class, 'destroy'])->whereNumber('id');

                Route::post('{id}/join',    [\App\Http\Controllers\Api\ClubsController::class, 'join'])->whereNumber('id');
                Route::post('{id}/leave',   [\App\Http\Controllers\Api\ClubsController::class, 'leave'])->whereNumber('id');
                Route::get('{id}/events',   [\App\Http\Controllers\Api\EventsController::class, 'byClub'])->whereNumber('id');
                Route::get('{id}/members',  [\App\Http\Controllers\Api\ClubsController::class, 'members'])->whereNumber('id');
                Route::post('{id}/logo',    [\App\Http\Controllers\Api\ClubsController::class, 'uploadLogo'])->whereNumber('id');
                Route::get('{id}/discuss',  [\App\Http\Controllers\Api\ClubsController::class, 'threads'])->whereNumber('id');
                Route::post('{id}/discuss', [\App\Http\Controllers\Api\ClubsController::class, 'newThread'])->whereNumber('id');
                Route::post('{id}/polls',   [\App\Http\Controllers\Api\ClubsController::class, 'createPoll'])->whereNumber('id');
            });
        });
    }

    /* ----------------------------------------
    |  Мероприятия (соревнования/фестивали)
    |-----------------------------------------*/
    if (config('feature.events', true)) {
        Route::prefix('events')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\EventsController::class, 'index']);     // ?region=
            Route::get('{id}', [\App\Http\Controllers\Api\EventsController::class, 'show'])->whereNumber('id');

            Route::middleware('auth:sanctum')->group(function () {
                Route::post('/', [\App\Http\Controllers\Api\EventsController::class, 'store']);
                Route::put('{id}', [\App\Http\Controllers\Api\EventsController::class, 'update'])->whereNumber('id');
                Route::delete('{id}', [\App\Http\Controllers\Api\EventsController::class, 'destroy'])->whereNumber('id');
                Route::post('{id}/subscribe', [\App\Http\Controllers\Api\EventsController::class, 'subscribe'])->whereNumber('id');
                Route::post('{id}/notify',    [\App\Http\Controllers\Api\EventsController::class, 'notifySubscribers'])->whereNumber('id');
            });
        });
    }

    /* ----------------------------------------
    |  Справочники
    |-----------------------------------------*/
    Route::prefix('reference')->group(function () {
        Route::get('fish',   [\App\Http\Controllers\Api\ReferenceController::class, 'fish']);   // виды рыб
        Route::get('knots',  [\App\Http\Controllers\Api\ReferenceController::class, 'knots']);  // узлы
        Route::get('tackle', [\App\Http\Controllers\Api\ReferenceController::class, 'tackle']); // снасти и приманки
        Route::get('styles', [\App\Http\Controllers\Api\ReferenceController::class, 'styles']); // виды рыбалок
        Route::get('recipes',[\App\Http\Controllers\Api\ReferenceController::class, 'recipes']);
        Route::get('search', [\App\Http\Controllers\Api\ReferenceController::class, 'search']); // быстрый поиск
    });

    /* ----------------------------------------
    |  Рейтинги и достижения
    |-----------------------------------------*/
    Route::prefix('ratings')->group(function () {
        Route::get('top', [\App\Http\Controllers\Api\RatingsController::class, 'top']);   // Топ-100 за год
        Route::get('daily',   [\App\Http\Controllers\Api\RatingsController::class, 'daily']);
        Route::get('weekly',  [\App\Http\Controllers\Api\RatingsController::class, 'weekly']);
        Route::get('monthly', [\App\Http\Controllers\Api\RatingsController::class, 'monthly']);
        Route::get('diversity',[\App\Http\Controllers\Api\RatingsController::class, 'diversity']); // разнообразие видов
    });

    /* ----------------------------------------
    |  Монетизация / Платежи
    |-----------------------------------------*/
    if (config('feature.payments', true)) {
        Route::middleware('auth:sanctum')->prefix('billing')->group(function () {
            Route::get('plans', [\App\Http\Controllers\Api\BillingController::class, 'plans']);
            Route::post('subscribe', [\App\Http\Controllers\Api\BillingController::class, 'subscribe']); // автопродление
            Route::post('oneoff',    [\App\Http\Controllers\Api\BillingController::class, 'oneOff']);    // разовые платежи
            Route::get('history',    [\App\Http\Controllers\Api\BillingController::class, 'history']);
        });
        // Вебхуки (без авторизации, но с проверкой сигнатур)
        Route::post('webhooks/stripe',   [\App\Http\Controllers\Api\Webhooks\StripeController::class, 'handle']);
        Route::post('webhooks/yookassa', [\App\Http\Controllers\Api\Webhooks\YooKassaController::class, 'handle']);
    }

    /* ----------------------------------------
    |  Поиск (глобальный)
    |-----------------------------------------*/
    Route::get('search', [\App\Http\Controllers\Api\SearchController::class, 'global']); // ?q=

    /* ----------------------------------------
    |  Погода
    |-----------------------------------------*/
    if (config('feature.weather', true)) {
        Route::get('weather', [\App\Http\Controllers\Api\WeatherController::class, 'get']); // ?lat=&lng=&units=&lang=
        Route::get('forecast', [\App\Http\Controllers\Api\WeatherController::class, 'forecast']); // 10-day
    }

    /* ----------------------------------------
    |  Избранное / Планирование / Медиа
    |-----------------------------------------*/
    Route::middleware('auth:sanctum')->group(function () {
        // избранные места/уловы/люди/клубы
        Route::prefix('favorites')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\FavoritesController::class, 'index']);
            Route::post('toggle', [\App\Http\Controllers\Api\FavoritesController::class, 'toggle']); // {type, id}
        });

        // планирование рыбалок
        Route::prefix('plans')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\PlansController::class, 'index']);
            Route::post('/', [\App\Http\Controllers\Api\PlansController::class, 'store']);
            Route::put('{id}', [\App\Http\Controllers\Api\PlansController::class, 'update'])->whereNumber('id');
            Route::delete('{id}', [\App\Http\Controllers\Api\PlansController::class, 'destroy'])->whereNumber('id');
            Route::post('{id}/invite', [\App\Http\Controllers\Api\PlansController::class, 'invite'])->whereNumber('id');
        });

        // медиа (общие загрузки)
        Route::post('media/upload', [\App\Http\Controllers\Api\MediaController::class, 'upload']);
        Route::delete('media/{id}', [\App\Http\Controllers\Api\MediaController::class, 'destroy'])->whereNumber('id');
    });

    /* ----------------------------------------
    |  Сезонность
    |-----------------------------------------*/
    Route::get('season', [\App\Http\Controllers\Api\SeasonController::class, 'resolve']); // ?date=&region=

    /* ----------------------------------------
    |  Admin (роль: admin/moderator)
    |-----------------------------------------*/
    Route::middleware(['auth:sanctum', 'can:admin-panel'])->prefix('admin')->group(function () {
        Route::get('dashboard', [\App\Http\Controllers\Api\Admin\DashboardController::class, 'stats']);

        // модерации
        Route::prefix('moderation')->group(function () {
            Route::get('points', [\App\Http\Controllers\Api\Admin\ModerationController::class, 'pointsQueue']);
            Route::post('points/{id}/approve', [\App\Http\Controllers\Api\Admin\ModerationController::class, 'approvePoint'])->whereNumber('id');
            Route::post('points/{id}/reject',  [\App\Http\Controllers\Api\Admin\ModerationController::class, 'rejectPoint'])->whereNumber('id');

            Route::get('comments', [\App\Http\Controllers\Api\Admin\ModerationController::class, 'commentsQueue']);
            Route::post('comments/{id}/approve', [\App\Http\Controllers\Api\Admin\ModerationController::class, 'approveComment'])->whereNumber('id');
            Route::post('comments/{id}/reject',  [\App\Http\Controllers\Api\Admin\ModerationController::class, 'rejectComment'])->whereNumber('id');
        });

        // справочники
        Route::prefix('reference')->group(function () {
            Route::post('fish',   [\App\Http\Controllers\Api\Admin\ReferenceController::class, 'createFish']);
            Route::put('fish/{id}', [\App\Http\Controllers\Api\Admin\ReferenceController::class, 'updateFish'])->whereNumber('id');
            Route::delete('fish/{id}', [\App\Http\Controllers\Api\Admin\ReferenceController::class, 'deleteFish'])->whereNumber('id');

            Route::post('knots',  [\App\Http\Controllers\Api\Admin\ReferenceController::class, 'createKnot']);
            Route::post('tackle', [\App\Http\Controllers\Api\Admin\ReferenceController::class, 'createTackle']);
            Route::post('styles', [\App\Http\Controllers\Api\Admin\ReferenceController::class, 'createStyle']);
            Route::post('recipes',[\App\Http\Controllers\Api\Admin\ReferenceController::class, 'createRecipe']);
        });

        // пользователи/роли
        Route::prefix('users')->group(function () {
            Route::get('/', [\App\Http\Controllers\Api\Admin\UsersController::class, 'index']);
            Route::post('{id}/role', [\App\Http\Controllers\Api\Admin\UsersController::class, 'setRole'])->whereNumber('id'); // admin/moderator/user
            Route::post('{id}/ban',  [\App\Http\Controllers\Api\Admin\UsersController::class, 'ban'])->whereNumber('id');
        });

        // биллинг/выплаты
        Route::prefix('billing')->group(function () {
            Route::get('payments', [\App\Http\Controllers\Api\Admin\BillingController::class, 'payments']);
            Route::get('subscriptions', [\App\Http\Controllers\Api\Admin\BillingController::class, 'subscriptions']);
            Route::post('plans', [\App\Http\Controllers\Api\Admin\BillingController::class, 'createPlan']);
        });
    });

    /* ----------------------------------------
    |  Тех.служебные (для cron/queues)
    |-----------------------------------------*/
    Route::middleware('signed')->prefix('jobs')->group(function () {
        Route::post('digest', [\App\Http\Controllers\Api\JobsController::class, 'sendDigests']); // рассылка дайджестов
        Route::post('reindex', [\App\Http\Controllers\Api\JobsController::class, 'reindexSearch']);
        Route::post('ratings/recalc', [\App\Http\Controllers\Api\JobsController::class, 'recalcRatings']);
        Route::post('subscriptions/renew', [\App\Http\Controllers\Api\JobsController::class, 'renewSubscriptions']);
    });
});

/* ----------------------------------------
|  Фолбэк 404 для API (опционально)
|-----------------------------------------*/
// Route::fallback(fn() => response()->json(['message' => 'Not Found'], 404));
