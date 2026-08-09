defmodule Terrarest.RouterTest do
  use Terrarest.TestCase, async: false

  setup [:set_mox_global, :verify_on_exit!]

  @test_port 4099

  describe "child_spec/1" do
    setup do
      mock_config(:terrarest, Terrarest.Router, port: @test_port)
    end

    test "starts endpoint" do
      content = ~s({"version": 1})

      mock(:read, fn _ -> {:ok, content} end)
      assert {:ok, _pid} = start_supervised(Terrarest.Router)

      assert {:ok, %Req.Response{status: 200, body: body}} =
               Req.get("http://localhost:#{@test_port}")

      assert JSON.decode!(content) == body
    end
  end
end
