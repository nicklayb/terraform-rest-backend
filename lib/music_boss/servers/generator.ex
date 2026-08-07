defmodule MusicBoss.Servers.Generator do
  @callback handle_update(map()) :: map()
  defmacro __using__(options) do
    quote do
      use GenServer

      require Logger

      @initial_state Keyword.get(unquote(options), :initial_state, %{})

      def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: Keyword.get(args, :name, __MODULE__))
      end

      def init(args) do
        send(self(), :update)
        {:ok, %{args: args, state: @initial_state, task: nil}}
      end

      def state do
        GenServer.call(__MODULE__, :state)
      end

      def update do
        send(__MODULE__, :update)
      end

      def handle_info(:update, %{task: nil} = state) do
        task = Task.async(fn -> handle_update(state.state) end)
        {:noreply, %{state | task: task}}
      end

      def handle_info(:update, state) do
        Logger.warning("[#{inspect(__MODULE__)}] Cannot update, already updating.")
        {:noreply, state}
      end

      def handle_info({task_ref, return_value}, %{task: %Task{ref: task_ref}} = state) do
        new_state =
          case return_value do
            {:ok, new_state} ->
              Logger.debug("[#{inspect(__MODULE__)}] updated")
              new_state

            other ->
              Logger.error("[#{inspect(__MODULE__)}] #{inspect(other)}")
          end

        {:noreply, %{state | state: return_value}}
      end

      def handle_info({:DOWN, task_ref, _, _, reason}, state) do
        if reason != :normal do
          Logger.warning("[#{inspect(__MODULE__)}] Unexpected exit: #{inspect(reason)}")
        end

        {:noreply, %{state | task: nil}}
      end

      def handle_info(unhandled, state) do
        Logger.warning("[#{inspect(__MODULE__)}] Unhandled #{inspect(unhandled)}")
        {:noreply, state}
      end

      def handle_call(:state, _, state) do
        {:reply, state.state, state}
      end
    end
  end
end
