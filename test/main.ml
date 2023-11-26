open Ocamelot.CsvReader
open OUnit2

let general_csv =
  CsvReader.read_csv ~date:"   the date   " ~open_price:"Open" ~high_price:"hi"
    ~low_price:"Low" ~close_price:" Close" ~adj_price:"adj" ~volume:"vol1234 "
    "data/test/general.csv"

module CsvReaderTester = struct
  let string_of_opt f s =
    match s with
    | None -> "None"
    | Some x -> "Some " ^ f x

  let test_size out csv =
    "size test" >:: fun _ ->
    assert_equal ~printer:string_of_int out (CsvReader.size csv)

  let test_get_row ~n out csv =
    let size = CsvReader.size csv in
    if n < 0 || n >= size then
      "get row test, invalid index" >:: fun _ ->
      assert_raises Not_found (fun _ -> CsvReader.get_row csv n)
    else
      "get row test" >:: fun _ ->
      assert_equal out (CsvReader.get_row csv n |> CsvReader.string_of_row)

  let test_row_getter ~p ~f ~fname ~idx out csv =
    let size = CsvReader.size csv in
    let row = List.nth (CsvReader.head csv size) idx in
    fname ^ " test" >:: fun _ -> assert_equal ~printer:p out (f row)

  let test_col_getter ~p ~f ~fname ~fst ~lst csv =
    let col = f csv in
    let size = List.length col in
    let first = List.nth col 0 in
    let last = List.nth col (size - 1) in
    [
      ( fname ^ " test size" >:: fun _ ->
        assert_equal ~printer:string_of_int (CsvReader.size csv) size );
      (fname ^ " test first" >:: fun _ -> assert_equal ~printer:p fst first);
      (fname ^ " test last" >:: fun _ -> assert_equal ~printer:p lst last);
    ]

  let test_head_tail ~p ~n ~f csv =
    let rows =
      if f = "head" then CsvReader.head csv n else CsvReader.tail csv n
    in
    let rec test_gen ~p ~f rows acc =
      match rows with
      | [] -> acc
      | h :: t ->
          ( f ^ " test" >:: fun _ ->
            assert_equal ~printer:p (CsvReader.get_row rows (List.length acc)) h
          )
          :: test_gen ~p ~f t acc
    in
    test_gen ~p ~f rows []

  let size_tests =
    [
      test_size 9 general_csv;
      test_size 0 (CsvReader.head general_csv 0);
      test_size 3 (CsvReader.head general_csv 3);
      test_size 9 (CsvReader.head general_csv 9);
    ]

  let get_row_tests =
    [
      test_get_row ~n:(-1) "" general_csv;
      test_get_row ~n:0
        "Date: 2018-10-01, Open Price: 292.109985, High Price: 292.929993, Low \
         Price: 290.980011, Close Price: 291.730011, Adj Price: N/A, Volume: \
         62078900"
        general_csv;
      test_get_row ~n:9
        "Date: 2018-10-11, Open Price: N/A, High Price: 278.899994, Low Price: \
         270.359985, Close Price: 272.170013, Adj Price: 250.377533, Volume: \
         274840500"
        general_csv;
      test_get_row ~n:100 "" general_csv;
    ]

  let get_date_tests =
    [
      test_row_getter
        ~p:(string_of_opt (fun s -> s))
        ~f:CsvReader.get_date ~fname:"date getter" ~idx:0 (Some "2018-10-01")
        general_csv;
      test_row_getter
        ~p:(string_of_opt (fun s -> s))
        ~f:CsvReader.get_date ~fname:"date getter" ~idx:4 (Some "2018-10-05")
        general_csv;
      test_row_getter
        ~p:(string_of_opt (fun s -> s))
        ~f:CsvReader.get_date ~fname:"date getter" ~idx:5 None general_csv;
    ]

  let get_open_price_tests =
    [
      test_row_getter
        ~p:(string_of_opt string_of_float)
        ~f:CsvReader.get_open_price ~fname:"open price getter" ~idx:0
        (Some 292.109985) general_csv;
      test_row_getter
        ~p:(string_of_opt string_of_float)
        ~f:CsvReader.get_open_price ~fname:"open price getter" ~idx:5 None
        general_csv;
    ]

  let get_high_price_tests =
    [
      test_row_getter
        ~p:(string_of_opt string_of_float)
        ~f:CsvReader.get_high_price ~fname:"high price getter" ~idx:1
        (Some 292.359985) general_csv;
      test_row_getter
        ~p:(string_of_opt string_of_float)
        ~f:CsvReader.get_high_price ~fname:"high price getter" ~idx:2 None
        general_csv;
    ]

  let get_low_price_tests =
    [
      test_row_getter
        ~p:(string_of_opt string_of_float)
        ~f:CsvReader.get_low_price ~fname:"low price getter" ~idx:1
        (Some 291.140015) general_csv;
      test_row_getter
        ~p:(string_of_opt string_of_float)
        ~f:CsvReader.get_low_price ~fname:"low price getter" ~idx:6 None
        general_csv;
    ]

  let get_closing_price_tests =
    [
      test_row_getter
        ~p:(string_of_opt string_of_float)
        ~f:CsvReader.get_closing_price ~fname:"closing price getter" ~idx:0
        (Some 291.730011) general_csv;
      test_row_getter
        ~p:(string_of_opt string_of_float)
        ~f:CsvReader.get_closing_price ~fname:"closing price getter" ~idx:6 None
        general_csv;
    ]

  let get_volume_tests =
    [
      test_row_getter
        ~p:(string_of_opt string_of_int)
        ~f:CsvReader.get_volume ~fname:"volume getter" ~idx:0 (Some 62078900)
        general_csv;
      test_row_getter
        ~p:(string_of_opt string_of_int)
        ~f:CsvReader.get_volume ~fname:"volume getter" ~idx:2 None general_csv;
    ]

  let row_getter_tests =
    List.flatten
      [
        get_date_tests;
        get_open_price_tests;
        get_high_price_tests;
        get_low_price_tests;
        get_closing_price_tests;
        get_volume_tests;
      ]

  let col_getter_tests =
    List.flatten
      [
        test_col_getter
          ~p:(string_of_opt (fun s -> s))
          ~f:CsvReader.get_dates ~fname:"dates col getter"
          ~fst:(Some "2018-10-01") ~lst:(Some "2018-10-11") general_csv;
        test_col_getter
          ~p:(string_of_opt string_of_float)
          ~f:CsvReader.get_open_prices ~fname:"open prices col getter"
          ~fst:(Some 292.109985) ~lst:None general_csv;
        test_col_getter
          ~p:(string_of_opt string_of_float)
          ~f:CsvReader.get_high_prices ~fname:"high prices col getter"
          ~fst:(Some 292.929993) ~lst:(Some 278.899994) general_csv;
        test_col_getter
          ~p:(string_of_opt string_of_float)
          ~f:CsvReader.get_low_prices ~fname:"low prices col getter"
          ~fst:(Some 290.980011) ~lst:(Some 270.359985) general_csv;
        test_col_getter
          ~p:(string_of_opt string_of_float)
          ~f:CsvReader.get_closing_prices ~fname:"closing prices col getter"
          ~fst:(Some 291.730011) ~lst:(Some 272.170013) general_csv;
        test_col_getter
          ~p:(string_of_opt string_of_float)
          ~f:CsvReader.get_adj_prices ~fname:"adj prices col getter" ~fst:None
          ~lst:(Some 250.377533) general_csv;
        test_col_getter
          ~p:(string_of_opt string_of_int)
          ~f:CsvReader.get_volumes ~fname:"volumes col getter"
          ~fst:(Some 62078900) ~lst:(Some 274840500) general_csv;
      ]

  let head_tests =
    List.flatten
      [
        test_head_tail ~p:CsvReader.string_of_row ~n:(-1) ~f:"head" general_csv;
        test_head_tail ~p:CsvReader.string_of_row ~n:0 ~f:"head" general_csv;
        test_head_tail ~p:CsvReader.string_of_row ~n:3 ~f:"head" general_csv;
        test_head_tail ~p:CsvReader.string_of_row ~n:9 ~f:"head" general_csv;
        test_head_tail ~p:CsvReader.string_of_row ~n:100 ~f:"head" general_csv;
      ]

  let tail_tests =
    List.flatten
      [
        test_head_tail ~p:CsvReader.string_of_row ~n:(-1) ~f:"tail" general_csv;
        test_head_tail ~p:CsvReader.string_of_row ~n:0 ~f:"tail" general_csv;
        test_head_tail ~p:CsvReader.string_of_row ~n:3 ~f:"tail" general_csv;
        test_head_tail ~p:CsvReader.string_of_row ~n:9 ~f:"tail" general_csv;
        test_head_tail ~p:CsvReader.string_of_row ~n:100 ~f:"tail" general_csv;
      ]

  let all_tests =
    List.flatten
      [
        row_getter_tests;
        col_getter_tests;
        get_row_tests;
        size_tests;
        head_tests;
        tail_tests;
      ]
end

let csv_tests = List.flatten [ CsvReaderTester.all_tests ]
let suite = "main test suite" >::: List.flatten [ csv_tests ]
let _ = run_test_tt_main suite
