defmodule Stonks.Metrics do
  @moduledoc """
  The Metrics context.
  """

  import Ecto.Query, warn: false
  alias Stonks.Repo

  alias Stonks.Metrics.TwelvedataRequest

  @doc """
  Returns the list of twelvedata_requests.

  ## Examples

      iex> list_twelvedata_requests()
      [%TwelvedataRequest{}, ...]

  """
  def list_twelvedata_requests do
    Repo.all(TwelvedataRequest)
  end

  @doc """
  Gets a single twelvedata_request.

  Raises `Ecto.NoResultsError` if the Twelvedata request does not exist.

  ## Examples

      iex> get_twelvedata_request!(123)
      %TwelvedataRequest{}

      iex> get_twelvedata_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_twelvedata_request!(id), do: Repo.get!(TwelvedataRequest, id)

  @doc """
  Creates a twelvedata_request.

  ## Examples

      iex> create_twelvedata_request(%{field: value})
      {:ok, %TwelvedataRequest{}}

      iex> create_twelvedata_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_twelvedata_request(attrs \\ %{}) do
    %TwelvedataRequest{}
    |> TwelvedataRequest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a twelvedata_request.

  ## Examples

      iex> update_twelvedata_request(twelvedata_request, %{field: new_value})
      {:ok, %TwelvedataRequest{}}

      iex> update_twelvedata_request(twelvedata_request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_twelvedata_request(%TwelvedataRequest{} = twelvedata_request, attrs) do
    twelvedata_request
    |> TwelvedataRequest.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a twelvedata_request.

  ## Examples

      iex> delete_twelvedata_request(twelvedata_request)
      {:ok, %TwelvedataRequest{}}

      iex> delete_twelvedata_request(twelvedata_request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_twelvedata_request(%TwelvedataRequest{} = twelvedata_request) do
    Repo.delete(twelvedata_request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking twelvedata_request changes.

  ## Examples

      iex> change_twelvedata_request(twelvedata_request)
      %Ecto.Changeset{data: %TwelvedataRequest{}}

  """
  def change_twelvedata_request(%TwelvedataRequest{} = twelvedata_request, attrs \\ %{}) do
    TwelvedataRequest.changeset(twelvedata_request, attrs)
  end
end
