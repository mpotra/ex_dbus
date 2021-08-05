plugins = [{Nicene, []}]

shared_checks = [
  {Credo.Check.Consistency.ExceptionNames, []},
  {Credo.Check.Consistency.LineEndings, []},
  {Credo.Check.Consistency.ParameterPatternMatching, []},
  {Credo.Check.Consistency.SpaceAroundOperators, []},
  {Credo.Check.Consistency.SpaceInParentheses, []},
  {Credo.Check.Consistency.TabsOrSpaces, []},
  {Credo.Check.Design.TagTODO, []},
  {Credo.Check.Design.TagFIXME, []},
  {Credo.Check.Readability.AliasOrder, []},
  {Credo.Check.Readability.FunctionNames, []},
  {Credo.Check.Readability.ModuleAttributeNames, []},
  {Credo.Check.Readability.ModuleNames, []},
  {Credo.Check.Readability.ParenthesesInCondition, []},
  {Credo.Check.Readability.ParenthesesOnZeroArityDefs, [parens: true]},
  {Credo.Check.Readability.PredicateFunctionNames, []},
  {Credo.Check.Readability.PreferImplicitTry, []},
  {Credo.Check.Readability.RedundantBlankLines, []},
  {Credo.Check.Readability.Semicolons, []},
  {Credo.Check.Readability.SpaceAfterCommas, []},
  {Credo.Check.Readability.StringSigils, []},
  {Credo.Check.Readability.TrailingBlankLine, []},
  {Credo.Check.Readability.TrailingWhiteSpace, []},
  {Credo.Check.Readability.MaxLineLength,
   [
     max_length: 98,
     ignore_heredocs: false,
     ignore_definitions: false,
     ignore_strings: false
   ]},
  {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
  {Credo.Check.Readability.VariableNames, []},
  {Credo.Check.Readability.MultiAlias, false},
  {Credo.Check.Refactor.CondStatements, []},
  {Credo.Check.Refactor.CyclomaticComplexity, []},
  {Credo.Check.Refactor.FunctionArity, []},
  {Credo.Check.Refactor.LongQuoteBlocks, []},
  # Not compatible with 1.9 or higher
  {Credo.Check.Refactor.MapInto, false},
  {Credo.Check.Refactor.MatchInCondition, []},
  {Credo.Check.Refactor.NegatedConditionsInUnless, []},
  {Credo.Check.Refactor.NegatedConditionsWithElse, []},
  {Credo.Check.Refactor.Nesting, []},
  {Credo.Check.Refactor.UnlessWithElse, []},
  {Credo.Check.Refactor.WithClauses, []},
  {Credo.Check.Refactor.AppendSingleItem, []},
  {Credo.Check.Refactor.PipeChainStart, []},
  {Credo.Check.Refactor.DoubleBooleanNegation, []},
  {Credo.Check.Warning.BoolOperationOnSameValues, []},
  {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
  {Credo.Check.Warning.IExPry, []},
  {Credo.Check.Warning.IoInspect, []},
  # Not compatible with 1.9 or higher
  {Credo.Check.Warning.LazyLogging, false},
  {Credo.Check.Warning.OperationOnSameValues, []},
  {Credo.Check.Warning.OperationWithConstantResult, []},
  {Credo.Check.Warning.RaiseInsideRescue, []},
  {Credo.Check.Warning.UnusedEnumOperation, []},
  {Credo.Check.Warning.UnusedFileOperation, []},
  {Credo.Check.Warning.UnusedKeywordOperation, []},
  {Credo.Check.Warning.UnusedListOperation, []},
  {Credo.Check.Warning.UnusedPathOperation, []},
  {Credo.Check.Warning.UnusedRegexOperation, []},
  {Credo.Check.Warning.UnusedStringOperation, []},
  {Credo.Check.Warning.UnusedTupleOperation, []},
  {Credo.Check.Warning.UnsafeToAtom, []},
  {Credo.Check.Readability.SinglePipe, false},
  {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
  {Credo.Check.Consistency.UnusedVariableNames, false},
  {Credo.Check.Design.DuplicatedCode, false},
  {Credo.Check.Readability.AliasAs, false},
  {Credo.Check.Refactor.ABCSize, false},
  {Credo.Check.Refactor.ModuleDependencies, false},
  {Credo.Check.Refactor.VariableRebinding, false},
  {Credo.Check.Warning.MapGetUnsafePass, false},
  {Nicene.FileAndModuleName, false},
  {Nicene.TestsInTestFolder, []},
  {Nicene.NoSpecsPrivateFunctions, []},
  {Nicene.EnsureTestFilePattern, []}
]

old_files_checks = [
  {Credo.Check.Design.AliasUsage,
   [exit_status: 0, if_nested_deeper_than: 1, if_called_more_often_than: 1]},
  {Credo.Check.Readability.ModuleDoc, [exit_status: 0]},
  {Credo.Check.Readability.Specs, [exit_status: 0]},
  {Nicene.TrueFalseCaseStatements, [exit_status: 0]},
  {Nicene.FileTopToBottom, [exit_status: 0]},
  {Nicene.PublicFunctionsFirst, [exit_status: 0]},
  {Nicene.ConsistentFunctionDefinitions, [exit_status: 0]},
  {Nicene.UnnecessaryPatternMatching, [exit_status: 0]},
  {Nicene.DocumentGraphqlSchema, [exit_status: 0]},
  {Nicene.EctoSchemaDirectories, [exit_status: 0]},
  {Nicene.AliasImportGrouping, [exit_status: 0]}
]

new_files_checks = [
  {Credo.Check.Design.AliasUsage, [if_nested_deeper_than: 1, if_called_more_often_than: 1]},
  {Credo.Check.Readability.ModuleDoc, []},
  {Credo.Check.Readability.ParenthesesOnZeroArityDefs, [parens: true]},
  {Credo.Check.Readability.Specs, []},
  {Nicene.TrueFalseCaseStatements, []},
  {Nicene.FileTopToBottom, []},
  {Nicene.PublicFunctionsFirst, []},
  {Nicene.ConsistentFunctionDefinitions, []},
  {Nicene.UnnecessaryPatternMatching, []},
  {Nicene.DocumentGraphqlSchema, []},
  {Nicene.EctoSchemaDirectories, []},
  {Nicene.AliasImportGrouping, []}
]

shared_test_files_checks = [
  {Credo.Check.Consistency.ExceptionNames, false},
  {Credo.Check.Consistency.LineEndings, false},
  {Credo.Check.Consistency.ParameterPatternMatching, []},
  {Credo.Check.Consistency.SpaceAroundOperators, []},
  {Credo.Check.Consistency.SpaceInParentheses, []},
  {Credo.Check.Consistency.TabsOrSpaces, []},
  {Credo.Check.Design.TagTODO, false},
  {Credo.Check.Design.TagFIXME, false},
  {Credo.Check.Readability.AliasOrder, false},
  {Credo.Check.Readability.FunctionNames, []},
  {Credo.Check.Readability.ModuleAttributeNames, []},
  {Credo.Check.Readability.ModuleNames, []},
  {Credo.Check.Readability.ParenthesesInCondition, []},
  {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
  {Credo.Check.Readability.PredicateFunctionNames, []},
  {Credo.Check.Readability.PreferImplicitTry, []},
  {Credo.Check.Readability.RedundantBlankLines, []},
  {Credo.Check.Readability.Semicolons, []},
  {Credo.Check.Readability.SpaceAfterCommas, []},
  {Credo.Check.Readability.StringSigils, []},
  {Credo.Check.Readability.TrailingBlankLine, []},
  {Credo.Check.Readability.TrailingWhiteSpace, []},
  {Credo.Check.Readability.MaxLineLength, false},
  {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
  {Credo.Check.Readability.VariableNames, []},
  {Credo.Check.Readability.MultiAlias, false},
  {Credo.Check.Refactor.CondStatements, []},
  {Credo.Check.Refactor.CyclomaticComplexity, false},
  {Credo.Check.Refactor.FunctionArity, []},
  {Credo.Check.Refactor.LongQuoteBlocks, []},
  # Not compatible with 1.9 or higher
  {Credo.Check.Refactor.MapInto, false},
  {Credo.Check.Refactor.MatchInCondition, []},
  {Credo.Check.Refactor.NegatedConditionsInUnless, []},
  {Credo.Check.Refactor.NegatedConditionsWithElse, []},
  {Credo.Check.Refactor.Nesting, []},
  {Credo.Check.Refactor.UnlessWithElse, []},
  {Credo.Check.Refactor.WithClauses, []},
  {Credo.Check.Refactor.AppendSingleItem, []},
  {Credo.Check.Refactor.PipeChainStart, false},
  {Credo.Check.Refactor.DoubleBooleanNegation, []},
  {Credo.Check.Warning.BoolOperationOnSameValues, []},
  {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
  {Credo.Check.Warning.IExPry, []},
  {Credo.Check.Warning.IoInspect, []},
  # Not compatible with 1.9 or higher
  {Credo.Check.Warning.LazyLogging, false},
  {Credo.Check.Warning.OperationOnSameValues, []},
  {Credo.Check.Warning.OperationWithConstantResult, []},
  {Credo.Check.Warning.RaiseInsideRescue, []},
  {Credo.Check.Warning.UnusedEnumOperation, []},
  {Credo.Check.Warning.UnusedFileOperation, []},
  {Credo.Check.Warning.UnusedKeywordOperation, []},
  {Credo.Check.Warning.UnusedListOperation, []},
  {Credo.Check.Warning.UnusedPathOperation, []},
  {Credo.Check.Warning.UnusedRegexOperation, []},
  {Credo.Check.Warning.UnusedStringOperation, []},
  {Credo.Check.Warning.UnusedTupleOperation, []},
  {Credo.Check.Warning.UnsafeToAtom, false},
  {Credo.Check.Readability.SinglePipe, false},
  {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
  {Credo.Check.Consistency.UnusedVariableNames, false},
  {Credo.Check.Design.DuplicatedCode, false},
  {Credo.Check.Readability.AliasAs, false},
  {Credo.Check.Refactor.ABCSize, false},
  {Credo.Check.Refactor.ModuleDependencies, false},
  {Credo.Check.Refactor.VariableRebinding, false},
  {Credo.Check.Warning.MapGetUnsafePass, false},
  {Nicene.FileAndModuleName, false},
  {Nicene.TestsInTestFolder, false},
  {Nicene.NoSpecsPrivateFunctions, []},
  {Credo.Check.Readability.ModuleDoc, false},
  {Credo.Check.Readability.ParenthesesOnZeroArityDefs, [parens: true]},
  {Credo.Check.Readability.Specs, false},
  {Nicene.TrueFalseCaseStatements, []},
  {Nicene.PublicFunctionsFirst, false},
  {Nicene.ConsistentFunctionDefinitions, false},
  {Nicene.DocumentGraphqlSchema, false},
  {Nicene.EctoSchemaDirectories, false},
  {Nicene.UnnecessaryPatternMatching, false},
  {Nicene.EnsureTestFilePattern, []}
]

old_test_files_checks = [
  {Credo.Check.Design.AliasUsage,
   [exit_status: 0, if_nested_deeper_than: 1, if_called_more_often_than: 1]},
  {Nicene.FileTopToBottom, [exit_status: 0]},
  {Nicene.AliasImportGrouping, [exit_status: 0]}
]

new_test_files_checks = [
  {Credo.Check.Design.AliasUsage, false},
  {Nicene.FileTopToBottom, false},
  {Nicene.AliasImportGrouping, false}
]

requires = []

%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["apps/", "lib/", "config/", "test/"],
        excluded: [~r"_build/", ~r"deps/", ~r"node_modules/", ~r"priv/", ~r"rel/"]
      },
      plugins: plugins,
      requires: [],
      strict: true,
      color: true,
      checks: old_files_checks ++ shared_checks
    },
    %{
      name: "new_files",
      files: %{
        included: ["apps/", "lib/", "config/"],
        excluded: [~r"_build/", ~r"deps/", ~r"node_modules/", ~r"priv/", ~r"rel/", ~r"test/"]
      },
      plugins: plugins,
      requires: [],
      strict: true,
      color: true,
      checks: new_files_checks ++ shared_checks
    },
    %{
      name: "new_test_files",
      files: %{
        included: ["test/"],
        excluded: [
          ~r"_build/",
          ~r"deps/",
          ~r"node_modules/",
          ~r"priv/",
          ~r"rel/",
          ~r"lib/",
          ~r"config/"
        ]
      },
      plugins: plugins,
      requires: [],
      strict: true,
      color: true,
      checks: new_test_files_checks ++ shared_test_files_checks
    },
    %{
      name: "old_test_files",
      files: %{
        included: ["test/"],
        excluded: [
          ~r"_build/",
          ~r"deps/",
          ~r"node_modules/",
          ~r"priv/",
          ~r"rel/",
          ~r"lib/",
          ~r"config/"
        ]
      },
      plugins: plugins,
      requires: [],
      strict: true,
      color: true,
      checks: old_test_files_checks ++ shared_test_files_checks
    }
  ]
}
