defmodule TutorialWeb.CookiesLive do
  use TutorialWeb, :live_view

  @topic "cookies"

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col items-center justify-center bg-gradient-to-b from-purple-900 to-red-900 text-white">
      <h1 class="absolute top-5 left-5 text-2xl font-bold">Cookie Clicker (多人模式)</h1>
      
      <div class="absolute top-5 right-5 text-sm bg-black/30 px-3 py-1 rounded">
        在线用户: {@online_users}
      </div>
      
      <div class="text-6xl mb-4">{@count}</div>
      
      <div :if={@last_amount > 0} class="text-lg text-yellow-300 mb-2 animate-pulse">
        +{@last_amount} cookies!
      </div>
      
      <div
        class="text-9xl cursor-pointer select-none transition-transform duration-100 hover:scale-110 active:scale-90"
        phx-click="increment_random"
        phx-keydown="increment_random"
        phx-key="Enter"
        tabindex="0"
      >
        🍪
      </div>
      
      <div class="mt-10 space-x-4">
        <button
          class="bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700 transition-colors"
          phx-click="increment"
          phx-value-amount="1"
        >
          +1
        </button>
        
        <button
          class="bg-green-600 text-white py-2 px-4 rounded hover:bg-green-700 transition-colors"
          phx-click="increment"
          phx-value-amount="5"
        >
          +5
        </button>
        
        <button
          class="bg-red-600 text-white py-2 px-4 rounded hover:bg-red-700 transition-colors"
          phx-click="increment"
          phx-value-amount="10"
        >
          +10
        </button>
        
        <button
          class="bg-purple-600 text-white py-2 px-4 rounded hover:bg-purple-700 transition-colors"
          phx-click="reset"
        >
          重置
        </button>
      </div>
      
      <div class="mt-4 text-sm text-gray-300">
        点击 🍪 获得 1-10 个随机 cookies！所有玩家共享同一个计数器
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # 订阅 cookies 主题以接收广播
      Phoenix.PubSub.subscribe(Tutorial.PubSub, @topic)

      # 通知其他用户有新用户加入
      broadcast_user_joined()
    end

    # 从 ETS 获取当前计数，如果没有则初始化为 0
    current_count = get_global_count()
    online_users = get_online_users()

    {:ok, assign(socket, count: current_count, online_users: online_users, last_amount: 0)}
  end

  def handle_event("increment_random", _params, socket) do
    # 生成1-10的随机数
    random_amount = Enum.random(1..10)
    new_count = update_global_count(random_amount)

    # 广播给所有连接的用户，包含随机数信息
    broadcast_count_update(new_count, random_amount)

    {:noreply, assign(socket, count: new_count, last_amount: random_amount)}
  end

  def handle_event("increment", %{"amount" => amount}, socket) do
    increment_amount = String.to_integer(amount)
    new_count = update_global_count(increment_amount)

    # 广播给所有连接的用户
    broadcast_count_update(new_count, increment_amount)

    {:noreply, assign(socket, count: new_count, last_amount: increment_amount)}
  end

  def handle_event("reset", _params, socket) do
    reset_global_count()
    new_count = 0

    # 广播重置消息
    broadcast_count_update(new_count, 0)

    {:noreply, assign(socket, count: new_count, last_amount: 0)}
  end

  # 处理来自其他用户的广播消息
  def handle_info({:count_updated, new_count, amount}, socket) do
    {:noreply, assign(socket, count: new_count, last_amount: amount)}
  end

  def handle_info({:user_count_updated, online_users}, socket) do
    {:noreply, assign(socket, :online_users, online_users)}
  end

  def terminate(_reason, _socket) do
    # 用户离开时通知其他用户
    broadcast_user_left()
    :ok
  end

  # 私有函数 - 全局计数器管理
  defp get_global_count do
    case :ets.lookup(:cookies_counter, :count) do
      [{:count, value}] ->
        value

      [] ->
        :ets.insert(:cookies_counter, {:count, 0})
        0
    end
  end

  defp update_global_count(increment) do
    :ets.update_counter(:cookies_counter, :count, increment, {:count, 0})
  end

  defp reset_global_count do
    :ets.insert(:cookies_counter, {:count, 0})
  end

  # 在线用户计数
  defp get_online_users do
    case :ets.lookup(:cookies_counter, :users) do
      [{:users, count}] ->
        count

      [] ->
        :ets.insert(:cookies_counter, {:users, 0})
        0
    end
  end

  defp increment_user_count do
    :ets.update_counter(:cookies_counter, :users, 1, {:users, 0})
  end

  defp decrement_user_count do
    current = get_online_users()
    new_count = max(0, current - 1)
    :ets.insert(:cookies_counter, {:users, new_count})
    new_count
  end

  # 广播函数
  defp broadcast_count_update(count, amount) do
    Phoenix.PubSub.broadcast(Tutorial.PubSub, @topic, {:count_updated, count, amount})
  end

  defp broadcast_user_joined do
    new_user_count = increment_user_count()
    Phoenix.PubSub.broadcast(Tutorial.PubSub, @topic, {:user_count_updated, new_user_count})
  end

  defp broadcast_user_left do
    new_user_count = decrement_user_count()
    Phoenix.PubSub.broadcast(Tutorial.PubSub, @topic, {:user_count_updated, new_user_count})
  end
end
