open CsvReader
open MovingAverage
module Gp = Gnuplot

type moving_avg_type =
  | Simple
  | Exponential
  | Weighted
  | Triangular
  | VolumeAdjusted

module type GrapherType = sig
  val graph : ?m_averages:(moving_avg_type * int) list -> CsvReader.t -> unit
  (** [graph ?m_averages data] plots the given data along with specified moving
      averages.
      @param m_averages
        is an optional parameter specifying a list of moving average types and
        their respective periods. Defaults to 50, 100, and 200 day moving
        averages.
      @param data is the CSV data to be plotted. *)
end

module Grapher : GrapherType = struct
  let convert_data data =
    let convert_row row =
      let date = CsvReader.get_date row in
      let op = Option.value (CsvReader.get_open_price row) ~default:0. in
      let hi = Option.value (CsvReader.get_high_price row) ~default:0. in
      let lo = Option.value (CsvReader.get_low_price row) ~default:0. in
      let cl = Option.value (CsvReader.get_closing_price row) ~default:0. in
      (date, (op, hi, lo, cl))
    in
    List.map convert_row data

  let match_moving_avg (ma_type : moving_avg_type) :
      CsvReader.t -> int -> float option list =
    match ma_type with
    | Simple -> MovingAverage.simple_moving_avg
    | Exponential -> MovingAverage.exp_moving_avg
    | Weighted -> MovingAverage.weighted_moving_avg
    | Triangular -> MovingAverage.triangular_moving_avg
    | VolumeAdjusted -> MovingAverage.vol_adj_moving_avg

  let rec tuple_lists l1 l2 =
    if List.length l1 > List.length l2 then
      match l1 with
      | _ :: t -> tuple_lists t l2
      | _ -> failwith "error"
    else if List.length l1 < List.length l2 then
      match l2 with
      | _ :: t -> tuple_lists l1 t
      | _ -> failwith "error"
    else
      match (l1, l2) with
      | h1 :: t1, h2 :: t2 -> (h1, h2) :: tuple_lists t1 t2
      | _ -> []

  let filter_float_list (data : float option list) : float list =
    List.filter_map (fun x -> x) data

  let graph ?(m_averages = [ (Simple, 50); (Simple, 100); (Simple, 200) ]) data
      =
    let plot_data = convert_data data in
    let dates = List.map fst plot_data in

    (* Calculate all moving averages provided in the m_averages list *)
    let moving_avg_data_lists =
      List.map
        (fun (ma_type, ma_period) ->
          let ma_fun = match_moving_avg ma_type in
          filter_float_list (ma_fun data ma_period))
        m_averages
    in
    let data_mas =
      List.map (fun ma_data -> tuple_lists dates ma_data) moving_avg_data_lists
    in

    (* ... plotting logic ... *)
    let gp = Gp.create () in
    let candle_data = Gp.Series.candles_date_ohlc ~color:`Blue plot_data in
    let ma_series =
      List.mapi
        (fun i ma_data ->
          Gp.Series.lines_datey
            ~color:(List.nth [ `Magenta; `Green; `Red ] i)
            ma_data)
        data_mas
    in
    Gp.plot_many gp
      ~range:(Gp.Date (List.hd dates, List.hd (List.rev dates)))
      ~format:"%b %d'%y" (candle_data :: ma_series);
    Unix.sleep 1000
end
