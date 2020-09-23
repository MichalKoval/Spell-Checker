{ Spell Checker }
{ Michal Kovaľ, 1. ročník, skupina I33 }
{ zimní semestr 2015/2016 }
{ Programování I NPRG030 }

program Spell_Checker;
uses crt, dateutils, sysutils;

const M = 100;
      N = 100;
      ALPHABET_LENGTH = 26;
      FIRST_CHAR = 'a';
      LAST_CHAR = 'z';

type
  MatrixType = Array[0..M,0..N] of Byte;
  {Trie Node (Trie = the special kind of tree)}

  PNode = ^Node;
  Node = Record
    IsWord: Boolean;
    ArrOfPtrs: Array[FIRST_CHAR..LAST_CHAR] of PNode;
  end;

  PWordsRecord = ^WordsRecord;
  WordsRecord = Record
    AnotherWord: String;
    Next: PWordsRecord;
  end;

  PFile = ^Text;

function MinOfThreeValues(a, b, c: Byte): Byte;    {funkcia hlada najmensi z troch prvkov}
begin
  if((a<=b) and (a<=c)) then
  begin
    MinOfThreeValues:=a;
    Exit
  end;
  if((b<=a) and (b<=c)) then
  begin
    MinOfThreeValues:=b;
    Exit
  end;
  if((c<=a) and (c<=b)) then
  begin
    MinOfThreeValues:=c;
    Exit
  end
end;

function MinOfTwoValues(a, b: Byte): Byte;    {funkcia hlada najmensi z dvoch prvkov}
begin
  if (a<=b) then
  begin
    MinOfTwoValues:=a;
    Exit
  end
  else
  begin
    MinOfTwoValues:=b;
    Exit
  end
end;

function LevenshteinDistance(a: String; length_a: Byte; b: String; length_b: Byte;
                            MaxCost: Byte; var IsItWorthIt: Boolean): Byte;
var
  MatrixOfDistances: MatrixType;
  i,j: Byte;
begin
  MatrixOfDistances[0,0]:=0;
  for i:=1 to length_a do         {prvy riadok vyplneni od 0 .. M (length_a)}
    MatrixOfDistances[i,0]:=i;
  for i:=1 to length_b do         {prvy stlpec vyplneni od 0 .. N (length_b)}
    MatrixOfDistances[0,i]:=i;

  for j:=1 to length_b do
    for i:=1 to length_a do
    begin
      if (a[i] = b[j]) then
        MatrixOfDistances[i,j]:=MatrixOfDistances[i-1, j-1]
      else
        MatrixOfDistances[i,j]:=MinOfThreeValues(MatrixOfDistances[i-1, j] + 1,      {zmazat}
                                                 MatrixOfDistances[i, j-1] + 1,      {insert}
                                                 MatrixOfDistances[i-1, j-1] + 1);   {nahradit}

      if (i > 1) and (j > 1) and (a[i] = b[j-1]) and (a[i-1] = b[j]) then    {transpozicia dvoch znakov bezprostredne vedla seba}
        MatrixOfDistances[i,j]:=MinOfTwoValues(MatrixOfDistances[i,j],
                                               MatrixOfDistances[i-2,j-2] + 1);
    end;
  if (length_b <= length_a) then                                     { Tato podmienka ma za ulohu zistit, }
    if MatrixOfDistances[length_b, length_b] <= (MaxCost + 1) then   { ci sa oplati porovnavat aj nadalej. }
      IsItWorthIt:=True                                              { V prípade, že slovu chýba jedno písmeno, }
    else                                                             { je potrebne sa pri porovnani a prekoceni limitu }
      IsItWorthIt:=False                                             { pozriet aj na dalsie pismenko (preto + 1)}
  else IsItWorthIt:=True;

  LevenshteinDistance:=MatrixOfDistances[length_a, length_b];

  {{----vypis---------------}

  Write('      ');
  for i:=1 to length_a do
    Write('  ', a[i]);
  WriteLn;
  WriteLn(' ');
  for j:=0 to length_b do
  begin
    if (j = 0) then
      Write('   ')
    else
      Write('  ', b[j]);

    for i:=0 to length_a do
      Write(MatrixOfDistances[i,j]:3);
    WriteLn();
    WriteLn()
  end;
  {------------------------}}

end;



function CreateNewNode(is_word: Boolean): PNode;
var
  index: Char;
  NewNode: PNode;
begin
  New(NewNode);
  NewNode^.IsWord:=is_word;
  for index:=FIRST_CHAR to LAST_CHAR do
    NewNode^.ArrOfPtrs[index]:=NIL; {vsetkych potomkov v strome nastavime na NIL}
  CreateNewNode:=NewNode;
end;

procedure InsertWordToTrie(word: string; RootNode: PNode);
var
  i: Byte;
  p: PNode;
begin
  p:=RootNode;
  for i:=1 to Length(word) do
  begin
    if p^.ArrOfPtrs[word[i]] = NIL then     {ak neexistuje nasledujuci node/pismeno, tak pridame novy}
      if (i = Length(word)) then
        p^.ArrOfPtrs[word[i]]:=CreateNewNode(True)     {ak ide o posledne pismeno, pridame node so znackou True}
      else
        p^.ArrOfPtrs[word[i]]:=CreateNewNode(False)   {ak nejde o posledne pismeno, pridame node so znackou False}
    else if (i = Length(word)) then
           p^.ArrOfPtrs[word[i]]^.IsWord:=True;       {ak ide o posledne pismeno, ktore sa uz nachadza v strome zmenime znacku na True}

    p:=p^.ArrOfPtrs[word[i]];  {skocime na dalsi node/pismeno}
  end;
end;

procedure SearchCurrentIndex(CurrentNode: PNode; ListOfNodes: PWordsRecord; CurrentWord: String; CurrentWordSize: Byte;
                            Word: String; WordSize: Byte; MaxLevensDist: Byte);
var
  c: Char;
  CurrDist: Byte; {Current distance}
  IsItWorthIt: Boolean;
  n, p: PWordsRecord;

begin
  for c:=FIRST_CHAR to LAST_CHAR do
  begin
    if (CurrentNode^.ArrOfPtrs[c] <> NIL) then
    begin
      CurrentWord:=CurrentWord+c; {vetva nie je prazdna, porovnavane slovo zvacsime o pismeno danej vetvy}
      Inc(CurrentWordSize);       {zvacsime velkost slova o +1}

      CurrDist:=LevenshteinDistance(Word, WordSize, CurrentWord, CurrentWordSize, MaxLevensDist, IsItWorthIt);

      if (CurrDist <= MaxLevensDist) and (CurrentNode^.ArrOfPtrs[c]^.IsWord) then
        if (CurrDist = 0) then
          {WriteLn('Zhodne slovo: ', CurrentWord)}
          ListOfNodes^.AnotherWord:=CurrentWord  {do prveho prazdneho nodu sa prida zhodne slovo}
        else
          begin
            {WriteLn('Podobne slovo: ', CurrentWord);}
            p:=ListOfNodes;

            while (p^.Next <> NIL) do  { ak nie sme na konci spojaku so slovami, }
              p:=p^.Next;              { tak sa presunie pointer na koniec       }
                                       { a prida sa dalsie podobne slovo         }
            new(n);
            n^.AnotherWord:=CurrentWord;
            n^.Next:=NIL;
            p^.Next:=n;
          end;
      if (CurrentWordSize < (WordSize + MaxLevensDist)) and IsItWorthIt then
        SearchCurrentIndex(CurrentNode^.ArrOfPtrs[c], ListOfNodes, CurrentWord, CurrentWordSize,
                           Word, WordSize, MaxLevensDist);

      Delete(CurrentWord, Length(CurrentWord), 1);
      Dec(CurrentWordSize)
    end
  end
end;

function SearchForSimilarWords(RootNode: PNode; SomeWord: String): PWordsRecord;
var
  EmptyWord: String;
  Size: Byte;
  ListOfWords: PWordsRecord;
begin
  Size:=0;
  EmptyWord:='';
  new(ListOfWords);
  ListOfWords^.AnotherWord:=''; {prvy node bude prazdny pre zhodne slovo, ostane nodes budu tvorit podobne slova}
  ListOfWords^.Next:=NIL;
  SearchCurrentIndex(RootNode, ListOfWords, EmptyWord, Size, SomeWord, Length(SomeWord), 1);
  SearchForSimilarWords:=ListOfWords; {vrati zoznam najdenych slov (vratane zhodneho slova)}
end;

procedure SaveEachWordFromTrie(CurrentNode: PNode; CurrentWord: String; FilePointer: PFile);
var
  c: Char;
begin
  for c:=FIRST_CHAR to LAST_CHAR do
  begin
    if (CurrentNode^.ArrOfPtrs[c] <> NIL) then
    begin
      CurrentWord:=CurrentWord+c;

      if (CurrentNode^.ArrOfPtrs[c]^.IsWord) then
        WriteLn(FilePointer^, CurrentWord);
        {ak je v danom Node koniec slova prida sa slovo do suboru}

      SaveEachWordFromTrie(CurrentNode^.ArrOfPtrs[c], CurrentWord, FilePointer);
      {ak to nie je koniec slova hladame rekurzivne dalej}

      Delete(CurrentWord, Length(CurrentWord), 1);
    end
  end
end;

procedure SaveChangesInTDictionary(RootNode: PNode);  { v pripade pridania noveho slova }
var                                                                    { sa aktualizuje slovnik          }
  StartTime, EndTime: TDateTime;
  DiffMilliSeconds: Int64;
  f: Text;
  p: PFile; { ukazatel na typ Text}

begin
  p:=@f;
  StartTime:=Now;

  {--------------------------------------------}
  Assign(p^, 'dic_edit.dat');
  Rewrite(p^);

  {procedure SaveChangesInTDictionary() predame ukazatel na File typu Text,}
  {aby bol subor pristupny v kazdom vnoreni stromu, a mohli sme donho ukladat slova}

  SaveEachWordFromTrie(RootNode, '', p);

  Close(p^);
  {--------------------------------------------}

  EndTime:=Now;
  DiffMilliSeconds:=MilliSecondsBetween(EndTime,StartTime);
  WriteLn('Zmena v slovniku bola ulozena! (vid "dic_edit.dat")');
  WriteLn('Processing time: ', DiffMilliSeconds, ' ms.')
end;

function AddWordToDictionary(RootNode: PNode): Boolean;
var
  SomeWord: String;
  i: Byte;
  err: Boolean;
begin
  AddWordToDictionary:=False;
  WriteLn('Pridat nove slovo (Press "1": Back): ');
  While True do
  begin
    err:=False;
    ReadLn(SomeWord);

    if SomeWord = '' then
    begin
      TextBackground(Red);
      Write('Error: nespravny vstup! ("a" .. "z")');
      TextBackground(Black);
      WriteLn;
      Continue;
    end;

    SomeWord:=LowerCase(SomeWord);

    if SomeWord = '1' then exit;

    for i:=1 to Length(SomeWord) do
    begin
      if not (SomeWord[i] in [FIRST_CHAR..LAST_CHAR]) then
      begin
        TextBackground(Red);
        Write('Error: nespravny vstup! ("a" .. "z")');
        TextBackground(Black);
        WriteLn;
        err:=True;
        Break;
      end;
    end;
    if err then Continue;

    InsertWordToTrie(SomeWord, RootNode);
    AddWordToDictionary:=True;
    WriteLn;
    WriteLn('Slovo bolo pridane.');
    WriteLn;
    WriteLn('Pridat dalsie nove slovo (Press "1": Back): ');
  end;

end;

procedure SpellChecker(RootNode: PNode; Path: String);   {menu 1}
var
  c: Char;
  currentdir, fileName, SomeWord, LowerCaseWord: String;
  p, ListOfWords: PWordsRecord;
  f, o: Text;
  error: Boolean;

begin
  While True do
  begin
    TextBackground(Red);
    Write('Zadajte meno textoveho suboru (Press "\": Back):');
    TextBackground(Black);
    WriteLn;
    ReadLn(fileName);
    if fileName = '\' then exit;
    if FileExists(Path+fileName) then
      Break
    else
    begin
      TextBackground(Red);
      Write('Error: Subor neexistuje..');
      TextBackground(Black);
      WriteLn;
    end
  end;

  Assign(f, Path+fileName);
  Reset(f);

  if eof(f) then    {v pripade ze je subor prazdny}
  begin
    Close(f);
    WriteLn;
    Writeln('Subor ', filename, ' je prazdny.');
    WriteLn('...Naspat: Press ENTER...');
    ReadLn;
    Exit
  end;

  Assign(o, Path+'output.txt');
  Rewrite(o);
  WriteLn;
  error:=False;
  WriteLn('Chyby v texte:');
  WriteLn('--------------');
  while not eof(f) do
  begin
    SomeWord:='';
    Read(f, c);
    if (c in [FIRST_CHAR..LAST_CHAR]) or (c in ['A'..'Z']) then
    begin
      while (c in [FIRST_CHAR..LAST_CHAR]) or (c in ['A'..'Z']) do
      begin
        SomeWord:=SomeWord+c;
        Read(f, c)
      end;
      LowerCaseWord:=SomeWord;
      if (LowerCaseWord[1] in ['A' .. 'Z']) then  {v pripade ze by na vstupe bolo slovo }
        LowerCaseWord:=LowerCase(LowerCaseWord);  {s velkym zaciatocnym pismenom..      }

      ListOfWords:=SearchForSimilarWords(RootNode, LowerCaseWord);

      if (ListOfWords^.AnotherWord = '') then   {ak sa najdu chyby}
        error:=True;

      if ListOfWords^.AnotherWord = LowerCaseWord then {ak sa slovo zhoduje, nemenit}
        Write(o, SomeWord)
      else
      begin
        Write('[', SomeWord, '] -> ');
        Write(o, '[', SomeWord, '] -> ');

        p:=ListOfWords^.Next;  {alternativne slova k hladanemu slovu}
        if p<>NIL then
        begin
          Write('{');
          Write(o, '{');
          while p<>NIL do
          begin
            Write(p^.AnotherWord);
            Write(o, p^.AnotherWord);
            p:=p^.Next;
            if p <> NIL then
            begin
              Write(', ');
              Write(o, ', ')
            end
          end;
          WriteLn('}');
          Write(o, '}')
        end
        else
        begin
          WriteLn('{ nezname slovo }');
          Write(o, '{ nezname slovo }');
        end;
        While ListOfWords^.Next <> NIL do {zmazanie listu slov}
        begin
          p:=ListOfWords;
          ListOfWords:=ListOfWords^.Next;
          Dispose(p);
        end
      end
    end;

    Write(o, c);
  end;
  Close(f);
  Close(o);
  WriteLn;
  if not error then
    WriteLn('V texte sa nenasli chyby.')
  else
    Writeln('vystup je v subore.. output.txt');

  WriteLn('...Naspat: Press ENTER...');
  ReadLn;

end;

procedure SearchWordInDictionary(RootNode: PNode);   {menu 3}
var
  SomeWord: String;
  p, ListOfWords: PWordsRecord;
  i: Integer;
  err: Boolean;
begin
  WriteLn;
  WriteLn('Zadajte hladane slovo (Press 1: Back): ');
  While True do
    begin
      err:=False;
      ReadLn(SomeWord);

      if (SomeWord = '') then
      begin
        TextBackground(Red);
        Write('Error: nespravny vstup!');
        TextBackground(Black);
        WriteLn;
        Continue;
      end;

      if SomeWord = '1' then exit;   {press 1 to go back}

      for i:=1 to Length(SomeWord) do
        if not (SomeWord[i] in [FIRST_CHAR..LAST_CHAR]) and not (SomeWord[i] in ['A'..'Z']) then
        begin
          TextBackground(Red);
          Write('Error: nespravny vstup!');
          TextBackground(Black);
          WriteLn;
          err:=True;
          Break;
        end;
      if err then Continue;

      WriteLn;
      ListOfWords:=SearchForSimilarWords(RootNode, LowerCase(SomeWord));
      {funkcia hlada zhodne alebo podobne slova a vrati ukazatel na zoznam najdenych slov,}
      {prve slovo v zozname je zhodne, ostatne su alternativy}

      if ListOfWords^.AnotherWord <> '' then {ak existuje zhodne slovo, vypise sa}
      begin
        TextBackground(Green);
        Write(ListOfWords^.AnotherWord);
        TextBackground(Black);
        WriteLn;
      end
      else WriteLn('Nenasla sa zhoda.');

      WriteLn;

      p:=ListOfWords^.Next;  {alternativne slova k hladanemu slovu}
      if p<>NIL then
      begin
        Write('{');
        while p<>NIL do
        begin
          Write(p^.AnotherWord);
          p:=p^.Next;
          if p <> NIL then Write(', ');
        end;
        WriteLn('}')
      end
      else
        WriteLn('{ ziadne dalsie slova }');

      While ListOfWords^.Next <> NIL do {zmazanie listu slov}
      begin
        p:=ListOfWords;
        ListOfWords:=ListOfWords^.Next;
        Dispose(p);
      end;

      WriteLn;
      WriteLn('-------------------------------------------');
      WriteLn('Zadaj dalsie hladane slovo (Press 1: Back):')
    end;

end;


procedure ShowSelectMenu0;
begin
  TextColor(White);
  TextBackground(Brown);
  Writeln('   SpellChecker by Michal Koval   ');
  TextBackground(Black);
  Writeln;
  Writeln('Vyberte moznost a stlacte ENTER:');
  WriteLn('   1. Skontrolovat text');
  WriteLn('   2. Pridat slovo do slovnika');
  WriteLn('   3. Najst slovo v slovniku');
  WriteLn('   4. Ukoncit');
  WriteLn;
  Write('option> ');
end;

function ShowSelectMenu1_option: String;
var
  currentdir, Path, Str: String;
begin
  GetDir(0, Path);
  WriteLn('dir> ', Path, '\*.*');
  Write('Zvolit aktualny adresar? (Y/N): ');
  While True do
  begin
    ReadLn(Str);
    if (Str[1] in ['y', 'Y', 'n', 'N']) then
      Break
    else Write('Error: Vyberte znova: ');
  end;
  While (Str[1] = 'n') or (Str = 'N') do
  begin
    Write('dir> ');
    ReadLn(Path);
    if DirectoryExists(Path) then
      Break
    else WriteLn('Error: Adresar neexistuje..');
  end;
  WriteLn;

  if Path[Length(Path)] <> '\' then Path:=Path+'\';

  GetDir(0, currentdir);
  if Path <> (currentdir+'\') then
  begin
    WriteLn('dir> ', Path);
    WriteLn;
  end;

  ShowSelectMenu1_option:=Path;

end;

procedure ShowSelectMenu1;    {ShowMenu pre 1. Skontrolovat text}
begin
  TextBackground(Brown);
  Write('<- 1. ');
  TextBackground(10);
  WriteLn(' Skontrolovat text ');
  TextBackground(Black);
  WriteLn;

  {Write(' Skontrolovat text (Press 1: Back) ');}
end;

procedure ShowSelectMenu2;    {ShowMenu pre 2. Pridat slovo do slovnika}
begin
  TextBackground(Brown);
  Write('<- 2. ');
  TextBackground(10);
  WriteLn(' Pridat slovo do slovnika ');
  TextBackground(Black);
  WriteLn;

  {WriteLn('<- 2. Pridat slovo do slovnika (Press 1: Back)');}
end;

procedure ShowSelectMenu3;    {ShowMenu pre 3. Najst slovo v slovniku}
begin
  TextBackground(Brown);
  Write('<- 3. ');
  TextBackground(10);
  WriteLn(' Najst slovo v slovniku ');
  TextBackground(Black);
  WriteLn;

  {WriteLn('<- 3. Najst slovo v slovniku (Press 1: Back)');}
end;

procedure ShowSelectMenu4;    {ShowMenu pre 4. Ukoncit}
begin
  WriteLn('Thanks. Created by Michal Koval');
  WriteLn;
  WriteLn('Stlacte lubovolne tlacidlo pre EXIT ...');
  Readln;
end;

procedure SelectOption(RootNode: PNode);
var
  value, path: String;
  change: Boolean;
begin
  change:=False;
  While True do
  begin
    ShowSelectMenu0;
    ReadLn(value);
    if (Length(value)=1) and (value[1] in ['1','2','3','4']) then
    begin
      case value[1] of
        '1': begin
               ClrScr;
               ShowSelectMenu1;
               path:=ShowSelectMenu1_option;
               SpellChecker(RootNode, path);
               ClrScr
             end;
        '2': begin
               ClrScr;
               ShowSelectMenu2;
               change:=AddWordToDictionary(RootNode);
               ClrScr
             end;
        '3': begin
               ClrScr;
               ShowSelectMenu3;
               SearchWordInDictionary(RootNode);
               ClrScr
             end;
        '4': begin
               ClrScr;
               if change then SaveChangesInTDictionary(RootNode)
               else WriteLn('Ziadna zmena v slovniku.');
               ShowSelectMenu4;
               Exit
             end;
      end;
    end
    else
    begin
      ClrScr;
      WriteLn('Error: Vyberte znova:')
    end;
  end;
end;

var
  s, Word, CorrectWord, InCorrectWord: String;
  RootNode: PNode; {zaciatok stromu}
  f: Text;
  repeat_read: Boolean;
  StartTime, EndTime: TDateTime;
  DiffMilliSeconds, WordCount: Int64;

  i: Byte;
  c: Char;

begin
  RootNode:=CreateNewNode(False);
  StartTime:=Now;
  Assign(f, 'dic_edit.dat');
  Reset(f);
  WordCount:=0;
  While not eof(f) do
  begin
    ReadLn(f, Word);
    InsertWordToTrie(Word, RootNode);
    Inc(WordCount);
  end;
  Close(f);
  EndTime:=Now;

  DiffMilliSeconds:=MilliSecondsBetween(EndTime,StartTime);
  WriteLn('Number of words loaded: ', WordCount, '.');
  WriteLn('Processing time: ', DiffMilliSeconds, ' ms.');
  WriteLn('-------Loading Finished!-------');


  {While True do {rychlost vyhladavania jednotlivych slov}
  begin
    WriteLn('Zadaj hladane slovo( ''1'' -> Exit ): ');
    ReadLn(InCorrectWord);
    if InCorrectWord[1] = '1' then break;
    StartTime:=Now;
    SearchForSimilarWords(RootNode, InCorrectWord);
    EndTime:=Now;

    DiffMilliSeconds:=MilliSecondsBetween(EndTime,StartTime);
    WriteLn('Processing time: ', DiffMilliSeconds, ' ms.');

    WriteLn;
    WriteLn('---------------------------------------');
  end;}

  SelectOption(RootNode);   {hlavne menu programu}
end.
