TextEditor = null
buildTextEditor = (params) ->
  if atom.workspace.buildTextEditor?
    atom.workspace.buildTextEditor(params)
  else
    TextEditor ?= require('atom').TextEditor
    new TextEditor(params)

describe "Language-XC", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-xc')

  describe "XC", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.xc')

    it "parses the grammar", ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.xc'

    it "tokenizes punctuation", ->
      {tokens} = grammar.tokenizeLine 'hi;'
      expect(tokens[1]).toEqual value: ';', scopes: ['source.xc', 'punctuation.terminator.statement.xc']

      {tokens} = grammar.tokenizeLine 'a[b]'
      expect(tokens[1]).toEqual value: '[', scopes: ['source.xc', 'punctuation.definition.begin.bracket.square.xc']
      expect(tokens[3]).toEqual value: ']', scopes: ['source.xc', 'punctuation.definition.end.bracket.square.xc']

      {tokens} = grammar.tokenizeLine 'a, b'
      expect(tokens[1]).toEqual value: ',', scopes: ['source.xc', 'punctuation.separator.delimiter.xc']

    it "tokenizes functions", ->
      lines = grammar.tokenizeLines '''
        int something(int param) {
          return 0;
        }
      '''
      expect(lines[0][0]).toEqual value: 'int', scopes: ['source.xc', 'storage.type.xc']
      expect(lines[0][2]).toEqual value: 'something', scopes: ['source.xc', 'meta.function.xc', 'entity.name.function.xc']
      expect(lines[0][3]).toEqual value: '(', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.begin.bracket.round.xc']
      expect(lines[0][4]).toEqual value: 'int', scopes: ['source.xc', 'meta.function.xc', 'storage.type.xc']
      expect(lines[0][6]).toEqual value: ')', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.end.bracket.round.xc']
      expect(lines[0][8]).toEqual value: '{', scopes: ['source.xc', 'meta.block.xc', 'punctuation.section.block.begin.bracket.curly.xc']
      expect(lines[1][1]).toEqual value: 'return', scopes: ['source.xc', 'meta.block.xc', 'keyword.control.xc']
      expect(lines[1][3]).toEqual value: '0', scopes: ['source.xc', 'meta.block.xc', 'constant.numeric.xc']
      expect(lines[2][0]).toEqual value: '}', scopes: ['source.xc', 'meta.block.xc', 'punctuation.section.block.end.bracket.curly.xc']

    it "tokenizes varargs ellipses", ->
      {tokens} = grammar.tokenizeLine 'void function(...);'
      expect(tokens[0]).toEqual value: 'void', scopes: ['source.xc', 'storage.type.xc']
      expect(tokens[2]).toEqual value: 'function', scopes: ['source.xc', 'meta.function.xc', 'entity.name.function.xc']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.begin.bracket.round.xc']
      expect(tokens[4]).toEqual value: '...', scopes: ['source.xc', 'meta.function.xc', 'punctuation.vararg-ellipses.xc']
      expect(tokens[5]).toEqual value: ')', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.end.bracket.round.xc']

    it "tokenizes various _t types", ->
      {tokens} = grammar.tokenizeLine 'size_t var;'
      expect(tokens[0]).toEqual value: 'size_t', scopes: ['source.xc', 'support.type.sys-types.xc']

      {tokens} = grammar.tokenizeLine 'pthread_t var;'
      expect(tokens[0]).toEqual value: 'pthread_t', scopes: ['source.xc', 'support.type.pthread.xc']

      {tokens} = grammar.tokenizeLine 'int32_t var;'
      expect(tokens[0]).toEqual value: 'int32_t', scopes: ['source.xc', 'support.type.stdint.xc']

      {tokens} = grammar.tokenizeLine 'myType_t var;'
      expect(tokens[0]).toEqual value: 'myType_t', scopes: ['source.xc', 'support.type.posix-reserved.xc']

      {tokens} = grammar.tokenizeLine 'myType_if var;'
      expect(tokens[0]).toEqual value: 'myType_if', scopes: ['source.xc', 'support.type.xmos-reserved.xc']

    it "tokenizes 'line continuation' character", ->
      {tokens} = grammar.tokenizeLine 'ma' + '\\' + '\n' + 'in(){};'
      expect(tokens[0]).toEqual value: 'ma', scopes: ['source.xc']
      expect(tokens[1]).toEqual value: '\\', scopes: ['source.xc', 'constant.character.escape.line-continuation.xc']
      expect(tokens[3]).toEqual value: 'in', scopes: ['source.xc', 'meta.function.xc', 'entity.name.function.xc']

    describe "strings", ->
      it "tokenizes them", ->
        delimsByScope =
          'string.quoted.double.xc': '"'
          'string.quoted.single.xc': '\''

        for scope, delim of delimsByScope
          {tokens} = grammar.tokenizeLine delim + 'a' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.xc', scope, 'punctuation.definition.string.begin.xc']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.xc', scope]
          expect(tokens[2]).toEqual value: delim, scopes: ['source.xc', scope, 'punctuation.definition.string.end.xc']

          {tokens} = grammar.tokenizeLine delim + 'a' + '\\' + '\n' + 'b' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.xc', scope, 'punctuation.definition.string.begin.xc']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.xc', scope]
          expect(tokens[2]).toEqual value: '\\', scopes: ['source.xc', scope, 'constant.character.escape.line-continuation.xc']
          expect(tokens[4]).toEqual value: 'b', scopes: ['source.xc', scope]
          expect(tokens[5]).toEqual value: delim, scopes: ['source.xc', scope, 'punctuation.definition.string.end.xc']

        {tokens} = grammar.tokenizeLine '"%d"'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.xc', 'string.quoted.double.xc', 'punctuation.definition.string.begin.xc']
        expect(tokens[1]).toEqual value: '%d', scopes: ['source.xc', 'string.quoted.double.xc', 'constant.other.placeholder.xc']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.xc', 'string.quoted.double.xc', 'punctuation.definition.string.end.xc']

        {tokens} = grammar.tokenizeLine '"%"'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.xc', 'string.quoted.double.xc', 'punctuation.definition.string.begin.xc']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.xc', 'string.quoted.double.xc', 'invalid.illegal.placeholder.xc']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.xc', 'string.quoted.double.xc', 'punctuation.definition.string.end.xc']

        {tokens} = grammar.tokenizeLine '"%" PRId32'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.xc', 'string.quoted.double.xc', 'punctuation.definition.string.begin.xc']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.xc', 'string.quoted.double.xc']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.xc', 'string.quoted.double.xc', 'punctuation.definition.string.end.xc']

        {tokens} = grammar.tokenizeLine '"%" SCNd32'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.xc', 'string.quoted.double.xc', 'punctuation.definition.string.begin.xc']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.xc', 'string.quoted.double.xc']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.xc', 'string.quoted.double.xc', 'punctuation.definition.string.end.xc']

    describe "comments", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine '/**/'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.xc', 'comment.block.xc', 'punctuation.definition.comment.begin.xc']
        expect(tokens[1]).toEqual value: '*/', scopes: ['source.xc', 'comment.block.xc', 'punctuation.definition.comment.end.xc']

        {tokens} = grammar.tokenizeLine '/* foo */'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.xc', 'comment.block.xc', 'punctuation.definition.comment.begin.xc']
        expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.xc', 'comment.block.xc']
        expect(tokens[2]).toEqual value: '*/', scopes: ['source.xc', 'comment.block.xc', 'punctuation.definition.comment.end.xc']

        {tokens} = grammar.tokenizeLine '*/*'
        expect(tokens[0]).toEqual value: '*/*', scopes: ['source.xc', 'invalid.illegal.stray-comment-end.xc']

    describe "preprocessor directives", ->
      it "tokenizes '#line'", ->
        {tokens} = grammar.tokenizeLine '#line 151 "copy.c"'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.line.xc', 'punctuation.definition.directive.xc']
        expect(tokens[1]).toEqual value: 'line', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.line.xc']
        expect(tokens[3]).toEqual value: '151', scopes: ['source.xc', 'meta.preprocessor.xc', 'constant.numeric.xc']
        expect(tokens[5]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.xc', 'string.quoted.double.xc', 'punctuation.definition.string.begin.xc']
        expect(tokens[6]).toEqual value: 'copy.xc', scopes: ['source.xc', 'meta.preprocessor.xc', 'string.quoted.double.xc']
        expect(tokens[7]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.xc', 'string.quoted.double.xc', 'punctuation.definition.string.end.xc']

      it "tokenizes '#undef'", ->
        {tokens} = grammar.tokenizeLine '#undef FOO'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.undef.xc', 'punctuation.definition.directive.xc']
        expect(tokens[1]).toEqual value: 'undef', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.undef.xc']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.xc']
        expect(tokens[3]).toEqual value: 'FOO', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']

      it "tokenizes '#pragma'", ->
        {tokens} = grammar.tokenizeLine '#pragma once'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'keyword.control.directive.pragma.xc', 'punctuation.definition.directive.xc']
        expect(tokens[1]).toEqual value: 'pragma', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'keyword.control.directive.pragma.xc']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.pragma.xc']
        expect(tokens[3]).toEqual value: 'once', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'entity.other.attribute-name.pragma.preprocessor.xc']

        {tokens} = grammar.tokenizeLine '#pragma clang diagnostic ignored "-Wunused-variable"'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'keyword.control.directive.pragma.xc', 'punctuation.definition.directive.xc']
        expect(tokens[1]).toEqual value: 'pragma', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'keyword.control.directive.pragma.xc']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.pragma.xc']
        expect(tokens[3]).toEqual value: 'clang', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'entity.other.attribute-name.pragma.preprocessor.xc']
        expect(tokens[5]).toEqual value: 'diagnostic', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'entity.other.attribute-name.pragma.preprocessor.xc']
        expect(tokens[7]).toEqual value: 'ignored', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'entity.other.attribute-name.pragma.preprocessor.xc']
        expect(tokens[10]).toEqual value: '-Wunused-variable', scopes: ['source.xc', 'meta.preprocessor.pragma.xc', 'string.quoted.double.xc']

        {tokens} = grammar.tokenizeLine '#pragma mark – Initialization'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.section', 'meta.preprocessor.pragma.xc', 'keyword.control.directive.pragma.pragma-mark.xc',  'punctuation.definition.directive.xc']
        expect(tokens[1]).toEqual value: 'pragma mark', scopes: ['source.xc', 'meta.section',  'meta.preprocessor.pragma.xc', 'keyword.control.directive.pragma.pragma-mark.xc']
        expect(tokens[3]).toEqual value: '– Initialization', scopes: ['source.xc', 'meta.section',  'meta.preprocessor.pragma.xc', 'entity.name.tag.pragma-mark.xc']

      describe "define", ->
        it "tokenizes '#define [identifier name]'", ->
          {tokens} = grammar.tokenizeLine '#define _FILE_NAME_H_'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
          expect(tokens[3]).toEqual value: '_FILE_NAME_H_', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']

        it "tokenizes '#define [identifier name] [value]'", ->
          {tokens} = grammar.tokenizeLine '#define WIDTH 80'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
          expect(tokens[3]).toEqual value: 'WIDTH', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
          expect(tokens[5]).toEqual value: '80', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'constant.numeric.xc']

          {tokens} = grammar.tokenizeLine '#define ABC XYZ(1)'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
          expect(tokens[3]).toEqual value: 'ABC', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
          expect(tokens[4]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
          expect(tokens[5]).toEqual value: 'XYZ', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.function.xc', 'entity.name.function.xc']
          expect(tokens[6]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.function.xc', 'punctuation.section.arguments.begin.bracket.round.xc']
          expect(tokens[7]).toEqual value: '1', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.function.xc', 'constant.numeric.xc']
          expect(tokens[8]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.function.xc', 'punctuation.section.arguments.end.bracket.round.xc']

          {tokens} = grammar.tokenizeLine '#define PI_PLUS_ONE (3.14 + 1)'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
          expect(tokens[3]).toEqual value: 'PI_PLUS_ONE', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
          expect(tokens[4]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
          expect(tokens[5]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.section.parens.begin.bracket.round.xc']
          expect(tokens[6]).toEqual value: '3.14', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'constant.numeric.xc']
          expect(tokens[8]).toEqual value: '+', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.operator.xc']
          expect(tokens[10]).toEqual value: '1', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'constant.numeric.xc']
          expect(tokens[11]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.section.parens.end.bracket.round.xc']

        describe "macros", ->
          it "tokenizes them", ->
            {tokens} = grammar.tokenizeLine '#define INCREMENT(x) x++'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
            expect(tokens[3]).toEqual value: 'INCREMENT', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.begin.xc']
            expect(tokens[5]).toEqual value: 'x', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc']
            expect(tokens[6]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.end.xc']
            expect(tokens[7]).toEqual value: ' x', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
            expect(tokens[8]).toEqual value: '++', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.operator.increment.xc']

            {tokens} = grammar.tokenizeLine '#define MULT(x, y) (x) * (y)'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
            expect(tokens[3]).toEqual value: 'MULT', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.begin.xc']
            expect(tokens[5]).toEqual value: 'x', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc']
            expect(tokens[6]).toEqual value: ',', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc', 'punctuation.separator.parameters.xc']
            expect(tokens[7]).toEqual value: ' y', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc']
            expect(tokens[8]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.end.xc']
            expect(tokens[9]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
            expect(tokens[10]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.section.parens.begin.bracket.round.xc']
            expect(tokens[11]).toEqual value: 'x', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
            expect(tokens[12]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.section.parens.end.bracket.round.xc']
            expect(tokens[13]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
            expect(tokens[14]).toEqual value: '*', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.operator.xc']
            expect(tokens[15]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
            expect(tokens[16]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.section.parens.begin.bracket.round.xc']
            expect(tokens[17]).toEqual value: 'y', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
            expect(tokens[18]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.section.parens.end.bracket.round.xc']

            {tokens} = grammar.tokenizeLine '#define SWAP(a, b)  do { a ^= b; b ^= a; a ^= b; } while ( 0 )'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
            expect(tokens[3]).toEqual value: 'SWAP', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.begin.xc']
            expect(tokens[5]).toEqual value: 'a', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc']
            expect(tokens[6]).toEqual value: ',', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc', 'punctuation.separator.parameters.xc']
            expect(tokens[7]).toEqual value: ' b', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc']
            expect(tokens[8]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.end.xc']
            expect(tokens[10]).toEqual value: 'do', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.xc']
            expect(tokens[12]).toEqual value: '{', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.block.begin.bracket.curly.xc']
            expect(tokens[13]).toEqual value: ' a ', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc']
            expect(tokens[14]).toEqual value: '^=', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'keyword.operator.assignment.compound.bitwise.xc']
            expect(tokens[15]).toEqual value: ' b', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc']
            expect(tokens[16]).toEqual value: ';', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.terminator.statement.xc']
            expect(tokens[17]).toEqual value: ' b ', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc']
            expect(tokens[18]).toEqual value: '^=', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'keyword.operator.assignment.compound.bitwise.xc']
            expect(tokens[19]).toEqual value: ' a', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc']
            expect(tokens[20]).toEqual value: ';', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.terminator.statement.xc']
            expect(tokens[21]).toEqual value: ' a ', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc']
            expect(tokens[22]).toEqual value: '^=', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'keyword.operator.assignment.compound.bitwise.xc']
            expect(tokens[23]).toEqual value: ' b', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc']
            expect(tokens[24]).toEqual value: ';', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.terminator.statement.xc']
            expect(tokens[25]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc']
            expect(tokens[26]).toEqual value: '}', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.block.end.bracket.curly.xc']
            expect(tokens[28]).toEqual value: 'while', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.xc']
            expect(tokens[29]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.macro.xc']
            expect(tokens[30]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.section.parens.begin.bracket.round.xc']
            expect(tokens[32]).toEqual value: '0', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'constant.numeric.xc']
            expect(tokens[34]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.section.parens.end.bracket.round.xc']

          it "tokenizes multiline macros", ->
            lines = grammar.tokenizeLines '''
              #define max(a,b) (a>b)? \\
                                a:b
            '''
            expect(lines[0][17]).toEqual value: '\\', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'constant.character.escape.line-continuation.xc']
            expect(lines[1][0]).toEqual value: '                  a', scopes: ['source.xc', 'meta.preprocessor.macro.xc']

            lines = grammar.tokenizeLines '''
              #define SWAP(a, b)  { \\
                a ^= b; \\
                b ^= a; \\
                a ^= b; \\
              }
            '''
            expect(lines[0][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
            expect(lines[0][1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
            expect(lines[0][3]).toEqual value: 'SWAP', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
            expect(lines[0][4]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.begin.xc']
            expect(lines[0][5]).toEqual value: 'a', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc']
            expect(lines[0][6]).toEqual value: ',', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc', 'punctuation.separator.parameters.xc']
            expect(lines[0][7]).toEqual value: ' b', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc']
            expect(lines[0][8]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.end.xc']
            expect(lines[0][10]).toEqual value: '{', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.block.begin.bracket.curly.xc']
            expect(lines[0][12]).toEqual value: '\\', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'constant.character.escape.line-continuation.xc']
            expect(lines[1][1]).toEqual value: '^=', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'keyword.operator.assignment.compound.bitwise.xc']
            expect(lines[1][5]).toEqual value: '\\', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'constant.character.escape.line-continuation.xc']
            expect(lines[2][1]).toEqual value: '^=', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'keyword.operator.assignment.compound.bitwise.xc']
            expect(lines[2][5]).toEqual value: '\\', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'constant.character.escape.line-continuation.xc']
            expect(lines[3][1]).toEqual value: '^=', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'keyword.operator.assignment.compound.bitwise.xc']
            expect(lines[3][5]).toEqual value: '\\', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'constant.character.escape.line-continuation.xc']
            expect(lines[4][0]).toEqual value: '}', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.block.end.bracket.curly.xc']

          it "tokenizes complex definitions", ->
            lines = grammar.tokenizeLines '''
              #define MakeHook(name) struct HOOK name = {{false, 0L}, \\
              ((HOOKF)(*HookEnt)), ID("hook")}
            '''
            expect(lines[0][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
            expect(lines[0][1]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
            expect(lines[0][3]).toEqual value: 'MakeHook', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
            expect(lines[0][4]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.begin.xc']
            expect(lines[0][5]).toEqual value: 'name', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'variable.parameter.preprocessor.xc']
            expect(lines[0][6]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'punctuation.definition.parameters.end.xc']
            expect(lines[0][8]).toEqual value: 'struct', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'storage.type.xc']
            expect(lines[0][10]).toEqual value: '=', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.operator.assignment.xc']
            expect(lines[0][12]).toEqual value: '{', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.block.begin.bracket.curly.xc']
            expect(lines[0][13]).toEqual value: '{', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.block.begin.bracket.curly.xc']
            expect(lines[0][14]).toEqual value: 'false', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'constant.language.xc']
            expect(lines[0][15]).toEqual value: ',', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.separator.delimiter.xc']
            expect(lines[0][17]).toEqual value: '0L', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'constant.numeric.xc']
            expect(lines[0][18]).toEqual value: '}', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.block.end.bracket.curly.xc']
            expect(lines[0][19]).toEqual value: ',', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.separator.delimiter.xc']
            expect(lines[0][21]).toEqual value: '\\', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'constant.character.escape.line-continuation.xc']
            expect(lines[1][0]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.parens.begin.bracket.round.xc']
            expect(lines[1][1]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.parens.begin.bracket.round.xc']
            expect(lines[1][3]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.parens.end.bracket.round.xc']
            expect(lines[1][4]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.parens.begin.bracket.round.xc']
            expect(lines[1][5]).toEqual value: '*', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'keyword.operator.xc']
            expect(lines[1][7]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.parens.end.bracket.round.xc']
            expect(lines[1][8]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.parens.end.bracket.round.xc']
            expect(lines[1][9]).toEqual value: ',', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.separator.delimiter.xc']
            expect(lines[1][11]).toEqual value: 'ID', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'meta.function.xc', 'entity.name.function.xc']
            expect(lines[1][12]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'meta.function.xc', 'punctuation.section.arguments.begin.bracket.round.xc']
            expect(lines[1][13]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'meta.function.xc', 'string.quoted.double.xc', "punctuation.definition.string.begin.c"]
            expect(lines[1][14]).toEqual value: 'hook', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'meta.function.xc', 'string.quoted.double.xc']
            expect(lines[1][15]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'meta.function.xc', 'string.quoted.double.xc', "punctuation.definition.string.end.c"]
            expect(lines[1][16]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'meta.function.xc', 'punctuation.section.arguments.end.bracket.round.xc']
            expect(lines[1][17]).toEqual value: '}', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'meta.block.xc', 'punctuation.section.block.end.bracket.curly.xc']

      describe "includes", ->
        it "tokenizes '#include'", ->
          {tokens} = grammar.tokenizeLine '#include <stdio.h>'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc']
          expect(tokens[3]).toEqual value: '<', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc', 'punctuation.definition.string.begin.xc']
          expect(tokens[4]).toEqual value: 'stdio.h', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc']
          expect(tokens[5]).toEqual value: '>', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc', 'punctuation.definition.string.end.xc']

          {tokens} = grammar.tokenizeLine '#include<stdio.h>'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc']
          expect(tokens[2]).toEqual value: '<', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc', 'punctuation.definition.string.begin.xc']
          expect(tokens[3]).toEqual value: 'stdio.h', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc']
          expect(tokens[4]).toEqual value: '>', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc', 'punctuation.definition.string.end.xc']

          {tokens} = grammar.tokenizeLine '#include_<stdio.h>'
          expect(tokens[0]).toEqual value: '#include_', scopes: ['source.xc']

          {tokens} = grammar.tokenizeLine '#include "file"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc', 'punctuation.definition.string.begin.xc']
          expect(tokens[4]).toEqual value: 'file', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc', 'punctuation.definition.string.end.xc']

        it "tokenizes '#import'", ->
          {tokens} = grammar.tokenizeLine '#import "file"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.import.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'import', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.import.xc']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc', 'punctuation.definition.string.begin.xc']
          expect(tokens[4]).toEqual value: 'file', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc', 'punctuation.definition.string.end.xc']

        it "tokenizes '#include_next'", ->
          {tokens} = grammar.tokenizeLine '#include_next "next.h"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include_next.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'include_next', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include_next.xc']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc', 'punctuation.definition.string.begin.xc']
          expect(tokens[4]).toEqual value: 'next.h', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.double.include.xc', 'punctuation.definition.string.end.xc']

      describe "diagnostics", ->
        it "tokenizes '#error'", ->
          {tokens} = grammar.tokenizeLine '#error "C++ compiler required."'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.diagnostic.xc', 'keyword.control.directive.diagnostic.error.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'error', scopes: ['source.xc', 'meta.preprocessor.diagnostic.xc', 'keyword.control.directive.diagnostic.error.xc']
          expect(tokens[4]).toEqual value: 'C++ compiler required.', scopes: ['source.xc', 'meta.preprocessor.diagnostic.xc', 'string.quoted.double.xc']

        it "tokenizes '#warning'", ->
          {tokens} = grammar.tokenizeLine '#warning "This is a warning."'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.diagnostic.xc', 'keyword.control.directive.diagnostic.warning.xc', 'punctuation.definition.directive.xc']
          expect(tokens[1]).toEqual value: 'warning', scopes: ['source.xc', 'meta.preprocessor.diagnostic.xc', 'keyword.control.directive.diagnostic.warning.xc']
          expect(tokens[4]).toEqual value: 'This is a warning.', scopes: ['source.xc', 'meta.preprocessor.diagnostic.xc', 'string.quoted.double.xc']

      describe "conditionals", ->
        it "tokenizes if-elif-else preprocessor blocks", ->
          lines = grammar.tokenizeLines '''
            #if defined(CREDIT)
                credit();
            #elif defined(DEBIT)
                debit();
            #else
                printerror();
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[0][3]).toEqual value: 'defined', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[0][5]).toEqual value: 'CREDIT', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[1][1]).toEqual value: 'credit', scopes: ['source.xc', 'meta.function.xc', 'entity.name.function.xc']
          expect(lines[1][2]).toEqual value: '(', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.begin.bracket.round.xc']
          expect(lines[1][3]).toEqual value: ')', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.end.bracket.round.xc']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[2][1]).toEqual value: 'elif', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[2][3]).toEqual value: 'defined', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[2][5]).toEqual value: 'DEBIT', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[3][1]).toEqual value: 'debit', scopes: ['source.xc', 'meta.function.xc', 'entity.name.function.xc']
          expect(lines[3][2]).toEqual value: '(', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.begin.bracket.round.xc']
          expect(lines[3][3]).toEqual value: ')', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.end.bracket.round.xc']
          expect(lines[4][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[4][1]).toEqual value: 'else', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[5][1]).toEqual value: 'printerror', scopes: ['source.xc', 'meta.function.xc', 'entity.name.function.xc']
          expect(lines[5][2]).toEqual value: '(', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.begin.bracket.round.xc']
          expect(lines[5][3]).toEqual value: ')', scopes: ['source.xc', 'meta.function.xc', 'punctuation.section.parameters.end.bracket.round.xc']
          expect(lines[6][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[6][1]).toEqual value: 'endif', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']

        it "tokenizes if-true-else blocks", ->
          lines = grammar.tokenizeLines '''
            #if 1
            int something() {
              #if 1
                return 1;
              #else
                return 0;
              #endif
            }
            #else
            int something() {
              return 0;
            }
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[0][3]).toEqual value: '1', scopes: ['source.xc', 'meta.preprocessor.xc', 'constant.numeric.xc']
          expect(lines[1][0]).toEqual value: 'int', scopes: ['source.xc', 'storage.type.xc']
          expect(lines[1][2]).toEqual value: 'something', scopes: ['source.xc', 'meta.function.xc', 'entity.name.function.xc']
          expect(lines[2][1]).toEqual value: '#', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[2][2]).toEqual value: 'if', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[2][4]).toEqual value: '1', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'constant.numeric.xc']
          expect(lines[3][1]).toEqual value: 'return', scopes: ['source.xc', 'meta.block.xc', 'keyword.control.xc']
          expect(lines[3][3]).toEqual value: '1', scopes: ['source.xc', 'meta.block.xc', 'constant.numeric.xc']
          expect(lines[4][1]).toEqual value: '#', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[4][2]).toEqual value: 'else', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[5][0]).toEqual value: '    return 0;', scopes: ['source.xc', 'meta.block.xc', 'comment.block.preprocessor.else-branch.in-block.xc']
          expect(lines[6][1]).toEqual value: '#', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[6][2]).toEqual value: 'endif', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[8][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[8][1]).toEqual value: 'else', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[9][0]).toEqual value: 'int something() {', scopes: ['source.xc', 'comment.block.preprocessor.else-branch.xc']
          expect(lines[12][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[12][1]).toEqual value: 'endif', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']

        it "tokenizes if-false-else blocks", ->
          lines = grammar.tokenizeLines '''
            int something() {
              #if 0
                return 1;
              #else
                return 0;
              #endif
            }
          '''
          expect(lines[0][0]).toEqual value: 'int', scopes: ['source.xc', 'storage.type.xc']
          expect(lines[0][2]).toEqual value: 'something', scopes: ['source.xc', 'meta.function.xc', 'entity.name.function.xc']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[1][2]).toEqual value: 'if', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[1][4]).toEqual value: '0', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'constant.numeric.xc']
          expect(lines[2][0]).toEqual value: '    return 1;', scopes: ['source.xc', 'meta.block.xc', 'comment.block.preprocessor.if-branch.in-block.xc']
          expect(lines[3][1]).toEqual value: '#', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[3][2]).toEqual value: 'else', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[4][1]).toEqual value: 'return', scopes: ['source.xc', 'meta.block.xc', 'keyword.control.xc']
          expect(lines[4][3]).toEqual value: '0', scopes: ['source.xc', 'meta.block.xc', 'constant.numeric.xc']
          expect(lines[5][1]).toEqual value: '#', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[5][2]).toEqual value: 'endif', scopes: ['source.xc', 'meta.block.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']

          lines = grammar.tokenizeLines '''
            #if 0
              something();
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[0][3]).toEqual value: '0', scopes: ['source.xc', 'meta.preprocessor.xc', 'constant.numeric.xc']
          expect(lines[1][0]).toEqual value: '  something();', scopes: ['source.xc', 'comment.block.preprocessor.if-branch.xc']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']

        it "tokenizes ifdef-elif blocks", ->
          lines = grammar.tokenizeLines '''
            #ifdef __unix__ /* is defined by compilers targeting Unix systems */
              # include <unistd.h>
            #elif defined _WIN32 /* is defined by compilers targeting Windows systems */
              # include <windows.h>
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[0][1]).toEqual value: 'ifdef', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[0][3]).toEqual value: '__unix__', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[0][5]).toEqual value: '/*', scopes: ['source.xc', 'comment.block.xc', 'punctuation.definition.comment.begin.xc']
          expect(lines[0][6]).toEqual value: ' is defined by compilers targeting Unix systems ', scopes: ['source.xc', 'comment.block.xc']
          expect(lines[0][7]).toEqual value: '*/', scopes: ['source.xc', 'comment.block.xc', 'punctuation.definition.comment.end.xc']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc', 'punctuation.definition.directive.xc']
          expect(lines[1][2]).toEqual value: ' include', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc']
          expect(lines[1][4]).toEqual value: '<', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc', 'punctuation.definition.string.begin.xc']
          expect(lines[1][5]).toEqual value: 'unistd.h', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc']
          expect(lines[1][6]).toEqual value: '>', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc', 'punctuation.definition.string.end.xc']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[2][1]).toEqual value: 'elif', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[2][3]).toEqual value: 'defined', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[2][5]).toEqual value: '_WIN32', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[2][7]).toEqual value: '/*', scopes: ['source.xc', 'comment.block.xc', 'punctuation.definition.comment.begin.xc']
          expect(lines[2][8]).toEqual value: ' is defined by compilers targeting Windows systems ', scopes: ['source.xc', 'comment.block.xc']
          expect(lines[2][9]).toEqual value: '*/', scopes: ['source.xc', 'comment.block.xc', 'punctuation.definition.comment.end.xc']
          expect(lines[3][1]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc', 'punctuation.definition.directive.xc']
          expect(lines[3][2]).toEqual value: ' include', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'keyword.control.directive.include.xc']
          expect(lines[3][4]).toEqual value: '<', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc', 'punctuation.definition.string.begin.xc']
          expect(lines[3][5]).toEqual value: 'windows.h', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc']
          expect(lines[3][6]).toEqual value: '>', scopes: ['source.xc', 'meta.preprocessor.include.xc', 'string.quoted.other.lt-gt.include.xc', 'punctuation.definition.string.end.xc']
          expect(lines[4][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[4][1]).toEqual value: 'endif', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']

        it "tokenizes ifndef blocks", ->
          lines = grammar.tokenizeLines '''
            #ifndef _INCL_GUARD
              #define _INCL_GUARD
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[0][1]).toEqual value: 'ifndef', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[0][3]).toEqual value: '_INCL_GUARD', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc', 'punctuation.definition.directive.xc']
          expect(lines[1][2]).toEqual value: 'define', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'keyword.control.directive.define.xc']
          expect(lines[1][4]).toEqual value: '_INCL_GUARD', scopes: ['source.xc', 'meta.preprocessor.macro.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc', 'punctuation.definition.directive.xc']
          expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']

        it "highlights stray elif, else and endif usages as invalid", ->
          lines = grammar.tokenizeLines '''
            #if defined SOMEMACRO
            #else
            #elif  //elif not permitted here
            #endif
            #else  //else without if
            #endif //endif without if
          '''
          expect(lines[2][0]).toEqual value: '#elif', scopes: ['source.xc', 'invalid.illegal.stray-elif.xc']
          expect(lines[4][0]).toEqual value: '#else', scopes: ['source.xc', 'invalid.illegal.stray-else.xc']
          expect(lines[5][0]).toEqual value: '#endif', scopes: ['source.xc', 'invalid.illegal.stray-endif.xc']

        it "highlights errorneous defined usage as invalid", ->
          {tokens} = grammar.tokenizeLine '#if defined == VALUE'
          expect(tokens[3]).toEqual value: 'defined', scopes: ['source.xc', 'meta.preprocessor.xc', 'invalid.illegal.macro-name.xc']

        it "tokenizes multi line conditional queries", ->
          lines = grammar.tokenizeLines '''
            #if !defined (MACRO_A) \\
             || !defined MACRO_C
              #define MACRO_A TRUE
            #elif MACRO_C == (5 + 4 -             /* multi line comment */  \\
                             SOMEMACRO(TRUE) * 8) // single line comment
            #endif
          '''
          expect(lines[0][2]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.xc']
          expect(lines[0][3]).toEqual value: '!', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.logical.xc']
          expect(lines[0][7]).toEqual value: 'MACRO_A', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[0][10]).toEqual value: '\\', scopes: ['source.xc', 'meta.preprocessor.xc', 'constant.character.escape.line-continuation.xc']
          expect(lines[1][1]).toEqual value: '||', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.logical.xc']
          expect(lines[1][3]).toEqual value: '!', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.logical.xc']
          expect(lines[1][4]).toEqual value: 'defined', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(lines[1][6]).toEqual value: 'MACRO_C', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[3][2]).toEqual value: ' ', scopes: ['source.xc', 'meta.preprocessor.xc']
          expect(lines[3][3]).toEqual value: 'MACRO_C', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[3][5]).toEqual value: '==', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.comparison.xc']
          expect(lines[3][7]).toEqual value: '(', scopes: ['source.xc', 'meta.preprocessor.xc', 'punctuation.section.parens.begin.bracket.round.xc']
          expect(lines[3][8]).toEqual value: '5', scopes: ['source.xc', 'meta.preprocessor.xc', 'constant.numeric.xc']
          expect(lines[3][10]).toEqual value: '+', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.xc']
          expect(lines[3][14]).toEqual value: '-', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.xc']
          expect(lines[3][16]).toEqual value: '/*', scopes: ['source.xc', 'meta.preprocessor.xc', 'comment.block.xc', 'punctuation.definition.comment.begin.xc']
          expect(lines[3][17]).toEqual value: ' multi line comment ', scopes: ['source.xc', 'meta.preprocessor.xc', 'comment.block.xc']
          expect(lines[3][18]).toEqual value: '*/', scopes: ['source.xc', 'meta.preprocessor.xc', 'comment.block.xc', 'punctuation.definition.comment.end.xc']
          expect(lines[3][20]).toEqual value: '\\', scopes: ['source.xc', 'meta.preprocessor.xc', 'constant.character.escape.line-continuation.xc']
          expect(lines[4][1]).toEqual value: 'SOMEMACRO', scopes: ['source.xc', 'meta.preprocessor.xc', 'entity.name.function.preprocessor.xc']
          expect(lines[4][3]).toEqual value: 'TRUE', scopes: ['source.xc', 'meta.preprocessor.xc', 'constant.language.xc']
          expect(lines[4][6]).toEqual value: '*', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.xc']
          expect(lines[4][9]).toEqual value: ')', scopes: ['source.xc', 'meta.preprocessor.xc', 'punctuation.section.parens.end.bracket.round.xc']
          expect(lines[4][11]).toEqual value: '//', scopes: ['source.xc', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
          expect(lines[4][12]).toEqual value: ' single line comment', scopes: ['source.xc', 'comment.line.double-slash.cpp']

        it "tokenizes ternary operator usage in preprocessor conditionals", ->
          {tokens} = grammar.tokenizeLine '#if defined (__GNU_LIBRARY__) ? defined (__USE_GNU) : !defined (__STRICT_ANSI__)'
          expect(tokens[9]).toEqual value: '?', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.ternary.xc']
          expect(tokens[11]).toEqual value: 'defined', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.control.directive.conditional.xc']
          expect(tokens[17]).toEqual value: ':', scopes: ['source.xc', 'meta.preprocessor.xc', 'keyword.operator.ternary.xc']

    describe "indentation", ->
      editor = null

      beforeEach ->
        editor = buildTextEditor()
        editor.setGrammar(grammar)

      expectPreservedIndentation = (text) ->
        editor.setText(text)
        editor.autoIndentBufferRows(0, editor.getLineCount() - 1)

        expectedLines = text.split('\n')
        actualLines = editor.getText().split('\n')
        for actualLine, i in actualLines
          expect([
            actualLine,
            editor.indentLevelForLine(actualLine)
          ]).toEqual([
            expectedLines[i],
            editor.indentLevelForLine(expectedLines[i])
          ])

      it "indents allman-style curly braces", ->
        expectPreservedIndentation '''
          if (a)
          {
            for (;;)
            {
              do
              {
                while (b)
                {
                  c();
                }
              }
              while (d)
            }
          }
        '''

      it "indents non-allman-style curly braces", ->
        expectPreservedIndentation '''
          if (a) {
            for (;;) {
              do {
                while (b) {
                  c();
                }
              } while (d)
            }
          }
        '''

      it "indents function arguments", ->
        expectPreservedIndentation '''
          a(
            b,
            c(
              d
            )
          );
        '''

      it "indents array and struct literals", ->
        expectPreservedIndentation '''
          some_t a[3] = {
            { .b = c },
            { .b = c, .d = {1, 2} },
          };
        '''

      it "tokenizes binary literal", ->
        {tokens} = grammar.tokenizeLine '0b101010'
        expect(tokens[0]).toEqual value: '0b101010', scopes: ['source.xc', 'constant.numeric.xc']

    describe "access", ->
      it "tokenizes the dot access operator", ->
        lines = grammar.tokenizeLines '''
          {
            a.
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.xc', 'meta.block.xc']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.dot-access.xc']

        lines = grammar.tokenizeLines '''
          {
            a.b;
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.xc', 'meta.block.xc']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.dot-access.xc']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'variable.other.member.xc']

        lines = grammar.tokenizeLines '''
          {
            a.b()
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.xc', 'meta.block.xc']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.dot-access.xc']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'meta.function-call.xc', 'entity.name.function.xc']

        lines = grammar.tokenizeLines '''
          {
            a. b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.dot-access.xc']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'variable.other.member.xc']

        lines = grammar.tokenizeLines '''
          {
            a .b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.dot-access.xc']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'variable.other.member.xc']

        lines = grammar.tokenizeLines '''
          {
            a . b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.dot-access.xc']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'variable.other.member.xc']

      it "tokenizes the pointer access operator", ->
        lines = grammar.tokenizeLines '''
          {
            a->b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.pointer-access.xc']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'variable.other.member.xc']

        lines = grammar.tokenizeLines '''
          {
            a->b()
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.xc', 'meta.block.xc']
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.pointer-access.xc']

        lines = grammar.tokenizeLines '''
          {
            a-> b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.pointer-access.xc']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'variable.other.member.xc']

        lines = grammar.tokenizeLines '''
          {
            a ->b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.pointer-access.xc']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'variable.other.member.xc']

        lines = grammar.tokenizeLines '''
          {
            a -> b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.pointer-access.xc']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.xc', 'meta.block.xc', 'variable.other.member.xc']

        lines = grammar.tokenizeLines '''
          {
            a->
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.xc', 'meta.block.xc']
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.xc', 'meta.block.xc', 'punctuation.separator.pointer-access.xc']

    describe "operators", ->
      it "tokenizes the sizeof operator", ->
        {tokens} = grammar.tokenizeLine('sizeof unary_expression')
        expect(tokens[0]).toEqual value: 'sizeof', scopes: ['source.xc', 'keyword.operator.sizeof.xc']
        expect(tokens[1]).toEqual value: ' unary_expression', scopes: ['source.xc']

        {tokens} = grammar.tokenizeLine('sizeof (int)')
        expect(tokens[0]).toEqual value: 'sizeof', scopes: ['source.xc', 'keyword.operator.sizeof.xc']
        expect(tokens[1]).toEqual value: ' ', scopes: ['source.xc']
        expect(tokens[2]).toEqual value: '(', scopes: ['source.xc', 'punctuation.section.parens.begin.bracket.round.xc']
        expect(tokens[3]).toEqual value: 'int', scopes: ['source.xc', 'storage.type.xc']
        expect(tokens[4]).toEqual value: ')', scopes: ['source.xc', 'punctuation.section.parens.end.bracket.round.xc']

        {tokens} = grammar.tokenizeLine('$sizeof')
        expect(tokens[1]).not.toEqual value: 'sizeof', scopes: ['source.xc', 'keyword.operator.sizeof.xc']

        {tokens} = grammar.tokenizeLine('sizeof$')
        expect(tokens[0]).not.toEqual value: 'sizeof', scopes: ['source.xc', 'keyword.operator.sizeof.xc']

        {tokens} = grammar.tokenizeLine('sizeof_')
        expect(tokens[0]).not.toEqual value: 'sizeof', scopes: ['source.xc', 'keyword.operator.sizeof.xc']

      it "tokenizes the increment operator", ->
        {tokens} = grammar.tokenizeLine('i++')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.xc']
        expect(tokens[1]).toEqual value: '++', scopes: ['source.xc', 'keyword.operator.increment.xc']

        {tokens} = grammar.tokenizeLine('++i')
        expect(tokens[0]).toEqual value: '++', scopes: ['source.xc', 'keyword.operator.increment.xc']
        expect(tokens[1]).toEqual value: 'i', scopes: ['source.xc']

      it "tokenizes the decrement operator", ->
        {tokens} = grammar.tokenizeLine('i--')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.xc']
        expect(tokens[1]).toEqual value: '--', scopes: ['source.xc', 'keyword.operator.decrement.xc']

        {tokens} = grammar.tokenizeLine('--i')
        expect(tokens[0]).toEqual value: '--', scopes: ['source.xc', 'keyword.operator.decrement.xc']
        expect(tokens[1]).toEqual value: 'i', scopes: ['source.xc']

      it "tokenizes logical operators", ->
        {tokens} = grammar.tokenizeLine('!a')
        expect(tokens[0]).toEqual value: '!', scopes: ['source.xc', 'keyword.operator.logical.xc']
        expect(tokens[1]).toEqual value: 'a', scopes: ['source.xc']

        operators = ['&&', '||']
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.xc', 'keyword.operator.logical.xc']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']

      it "tokenizes comparison operators", ->
        operators = ['<=', '>=', '!=', '==', '<', '>' ]

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.xc', 'keyword.operator.comparison.xc']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']

      it "tokenizes arithmetic operators", ->
        operators = ['+', '-', '*', '/', '%']

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.xc', 'keyword.operator.xc']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']

      it "tokenizes ternary operators", ->
        {tokens} = grammar.tokenizeLine('a ? b : c')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.xc', 'keyword.operator.ternary.xc']
        expect(tokens[2]).toEqual value: ' b ', scopes: ['source.xc']
        expect(tokens[3]).toEqual value: ':', scopes: ['source.xc', 'keyword.operator.ternary.xc']
        expect(tokens[4]).toEqual value: ' c', scopes: ['source.xc']

      it "tokenizes ternary operators with member access", ->
        {tokens} = grammar.tokenizeLine('a ? b.c : d')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.xc', 'keyword.operator.ternary.xc']
        expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']
        expect(tokens[3]).toEqual value: '.', scopes: ['source.xc', 'punctuation.separator.dot-access.xc']
        expect(tokens[4]).toEqual value: 'c', scopes: ['source.xc', 'variable.other.member.xc']
        expect(tokens[5]).toEqual value: ' ', scopes: ['source.xc']
        expect(tokens[6]).toEqual value: ':', scopes: ['source.xc', 'keyword.operator.ternary.xc']
        expect(tokens[7]).toEqual value: ' d', scopes: ['source.xc']

      it "tokenizes ternary operators with pointer dereferencing", ->
        {tokens} = grammar.tokenizeLine('a ? b->c : d')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.xc', 'keyword.operator.ternary.xc']
        expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']
        expect(tokens[3]).toEqual value: '->', scopes: ['source.xc', 'punctuation.separator.pointer-access.xc']
        expect(tokens[4]).toEqual value: 'c', scopes: ['source.xc', 'variable.other.member.xc']
        expect(tokens[5]).toEqual value: ' ', scopes: ['source.xc']
        expect(tokens[6]).toEqual value: ':', scopes: ['source.xc', 'keyword.operator.ternary.xc']
        expect(tokens[7]).toEqual value: ' d', scopes: ['source.xc']

      it "tokenizes ternary operators with function invocation", ->
        {tokens} = grammar.tokenizeLine('a ? f(b) : c')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.xc', 'keyword.operator.ternary.xc']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.xc']
        expect(tokens[3]).toEqual value: 'f', scopes: ['source.xc', 'meta.function-call.xc', 'entity.name.function.xc']
        expect(tokens[4]).toEqual value: '(', scopes: ['source.xc', 'meta.function-call.xc', 'punctuation.section.arguments.begin.bracket.round.xc']
        expect(tokens[5]).toEqual value: 'b', scopes: ['source.xc', 'meta.function-call.xc']
        expect(tokens[6]).toEqual value: ')', scopes: ['source.xc', 'meta.function-call.xc', 'punctuation.section.arguments.end.bracket.round.xc']
        expect(tokens[7]).toEqual value: ' ', scopes: ['source.xc']
        expect(tokens[8]).toEqual value: ':', scopes: ['source.xc', 'keyword.operator.ternary.xc']
        expect(tokens[9]).toEqual value: ' c', scopes: ['source.xc']

      describe "bitwise", ->
        it "tokenizes bitwise 'not'", ->
          {tokens} = grammar.tokenizeLine('~a')
          expect(tokens[0]).toEqual value: '~', scopes: ['source.xc', 'keyword.operator.xc']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.xc']

        it "tokenizes shift operators", ->
          {tokens} = grammar.tokenizeLine('>>')
          expect(tokens[0]).toEqual value: '>>', scopes: ['source.xc', 'keyword.operator.bitwise.shift.xc']

          {tokens} = grammar.tokenizeLine('<<')
          expect(tokens[0]).toEqual value: '<<', scopes: ['source.xc', 'keyword.operator.bitwise.shift.xc']

        it "tokenizes them", ->
          operators = ['|', '^', '&']

          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.xc', 'keyword.operator.xc']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']

      describe "assignment", ->
        it "tokenizes the assignment operator", ->
          {tokens} = grammar.tokenizeLine('a = b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
          expect(tokens[1]).toEqual value: '=', scopes: ['source.xc', 'keyword.operator.assignment.xc']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']

        it "tokenizes compound assignment operators", ->
          operators = ['+=', '-=', '*=', '/=', '%=']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.xc', 'keyword.operator.assignment.compound.xc']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']

        it "tokenizes bitwise compound operators", ->
          operators = ['<<=', '>>=', '&=', '^=', '|=']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.xc', 'keyword.operator.assignment.compound.bitwise.xc']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']

        it "tokenizes channel read/write operators", ->
          operatos = ['<:',':>']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + 'b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.xc']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.xc', 'keyword.operator.chan.xc']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.xc']
