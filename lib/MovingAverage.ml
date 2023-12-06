open CsvReader

module type MovingAverageType = sig
  val simple_moving_avg : CsvReader.t -> int -> float option list
  val exp_moving_avg : CsvReader.t -> int -> float option list
  val weighted_moving_avg : CsvReader.t -> int -> float option list
  val triangular_moving_avg : CsvReader.t -> int -> float option list
  val variable_moving_avg : CsvReader.t -> int -> float option list
end

(** TODO: case where n larger than list size -> just revert to size of list *)

module MovingAverage : MovingAverageType = struct
  let rec take n prices =
    match (prices, n) with
    | [], _ -> []
    | h :: _, 1 -> [ h ]
    | h :: t, n -> h :: take (n - 1) t

  (* let rec take_last n prices = match (prices, n) with | [], _ -> [] | _ :: t,
     1 -> t | _ :: t, n -> take_last (n - 1) t *)

  let rec divide_windows size prices =
    let len = List.length prices in
    if len < size then []
    else
      match prices with
      | [] -> []
      | _ :: t ->
          if len = size then [ prices ]
          else take size prices :: divide_windows size t

  let gen_windows data size =
    CsvReader.get_closing_prices data |> divide_windows size

  let valid_prices prices =
    let rec helper prices acc =
      match prices with
      | [] -> acc |> List.rev
      | None :: t -> helper t acc
      | Some price :: t -> helper t (price :: acc)
    in
    helper prices []

  let rec sum prices acc =
    match prices with
    | [] -> acc
    | price :: t -> sum t (acc +. price)

  let single_sma window =
    let valid_prices = valid_prices window in
    if List.length valid_prices = 0 then None
    else
      let sma =
        sum valid_prices 0. /. (List.length valid_prices |> float_of_int)
      in
      Some sma

  let simple_moving_avg data size =
    if size <= 0 then []
    else
      let windows = gen_windows data size in
      List.fold_left (fun acc window -> single_sma window :: acc) [] windows
      |> List.rev

  let single_ema window prev multiplier =
    let w_size = List.length window in
    let curr_price = List.nth window (w_size - 1) in
    match curr_price with
    | None -> None
    | Some price ->
        let ema = (price *. multiplier) +. (prev *. (1. -. multiplier)) in
        Some ema

  let exp_moving_avg data n =
    let n = min n (CsvReader.get_closing_prices data |> List.length) in
    if n <= 0 then []
    else
      let windows = gen_windows data n in
      let multiplier = 2. /. (float_of_int n +. 1.) in
      let init_ema = List.hd windows |> single_sma in

      let rec calculate_ema windows prev multiplier acc =
        match windows with
        | [] -> List.rev acc
        | h :: t ->
            let ema = single_ema h prev multiplier in
            if Option.is_some ema then
              calculate_ema t
                (Option.value ema ~default:0.)
                multiplier (ema :: acc)
            else calculate_ema t prev multiplier (ema :: acc)
      in
      if Option.is_none init_ema then []
      else
        calculate_ema windows (Option.value init_ema ~default:0.) multiplier []

  let single_wma window =
    let valid_prices = valid_prices window in
    if List.length valid_prices = 0 then None
    else
      let n = List.length valid_prices |> float_of_int in
      let den = n *. (n +. 1.) /. 2. in
      let rec w_sum prices n acc =
        match prices with
        | [] -> acc
        | h :: t ->
            let new_acc = (h *. n) +. acc in
            w_sum t (n -. 1.) new_acc
      in
      let sum = w_sum valid_prices n 0. in
      Some (sum /. den)

  let weighted_moving_avg data n =
    let n = min n (CsvReader.get_closing_prices data |> List.length) in
    if n <= 0 then []
    else
      let windows = gen_windows data n in
      List.fold_left (fun acc window -> single_wma window :: acc) [] windows
      |> List.rev

  (** https://tulipindicators.org/trima *)
  (* let rec single_tma = failwith "yres" *)

  let triangular_moving_avg data n =
    CsvReader.print_data data;
    print_int n;
    []
  (* if n <= 0 then [] else let sma = simple_moving_avg data n = let prices =
     take_last n data in List.fold_left (fun acc elem -> single_tma sma n ::
     acc) [] prices in failwith "yes" *)

  let variable_moving_avg data n =
    CsvReader.print_data data;
    print_int n;
    []
end
