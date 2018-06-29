%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Refactor.CyclomaticComplexity, max_complexity: 12},
        {Credo.Check.Refactor.LongQuoteBlocks, max_line_count: 300}
      ]
    }
  ]
}
