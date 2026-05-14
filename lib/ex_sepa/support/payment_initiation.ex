defmodule ExSepa.Support.PaymentInitiation do
  @moduledoc false

  @spec new(module(), map()) :: struct()
  def new(module, group_header) do
    case ExSepa.Schema.GroupHeader.new(group_header) do
      {:ok, parsed_group_header} ->
        struct(module, group_header: parsed_group_header)

      {:error, e} ->
        raise ExSepa.Schema.GroupHeaderError, message: e
    end
  end

  @spec add_payment_information(struct(), map(), module(), module()) :: struct()
  def add_payment_information(
        initiation,
        payment_information,
        payment_information_module,
        payment_information_error_module
      ) do
    case payment_information_module.new(payment_information) do
      {:ok, ok_payment_information} ->
        payment_information_list = initiation.payment_information || []

        if Enum.any?(
             payment_information_list,
             &(&1.payment_id == ok_payment_information.payment_id)
           ) do
          raise payment_information_error_module,
            message: "payment_id: #{ok_payment_information.payment_id} already exists"
        else
          struct(initiation,
            payment_information: [ok_payment_information | payment_information_list]
          )
        end

      {:error, e} ->
        raise payment_information_error_module, message: e
    end
  end

  @spec add_transaction_information(struct(), String.t(), map(), module(), module()) :: struct()
  def add_transaction_information(
        initiation,
        payment_id,
        transaction_information,
        transaction_information_module,
        transaction_information_error_module
      ) do
    payment_information_list =
      initiation.payment_information ||
        raise transaction_information_error_module,
          message:
            "There is no payment information yet. Please create one using the add_payment_information command."

    if Enum.any?(payment_information_list, &(&1.payment_id == payment_id)) do
      case transaction_information_module.new(transaction_information) do
        {:ok, ok_transaction_information} ->
          struct(initiation,
            payment_information:
              add_transaction_to_payment_information(
                payment_information_list,
                payment_id,
                ok_transaction_information
              )
          )

        {:error, e} ->
          raise transaction_information_error_module, message: e
      end
    else
      raise transaction_information_error_module,
        message: "payment_id: #{payment_id} does not exists in payment information"
    end
  end

  defp add_transaction_to_payment_information(list, payment_id, txinf, acc \\ [])
  defp add_transaction_to_payment_information([], _payment_id, _txinf, acc), do: Enum.reverse(acc)

  defp add_transaction_to_payment_information([first | rest], payment_id, txinf, acc) do
    updated_payment_information =
      if first.payment_id == payment_id do
        struct(first,
          transaction_information:
            if(first.transaction_information == nil,
              do: [txinf],
              else: [txinf | first.transaction_information]
            )
        )
      else
        first
      end

    add_transaction_to_payment_information(rest, payment_id, txinf, [
      updated_payment_information | acc
    ])
  end
end
