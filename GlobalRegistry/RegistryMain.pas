unit RegistryMain;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, ExtCtrls, Menus, Dialogs,
  StdCtrls, Graphics, ogcBasic, ogcRegistry, ValueEditForm;

const
  DEFAULT_REGISTRY_FILE = 'theGrapher.reg';

type
  { TRegistryMainForm }

  TRegistryMainForm = class(TForm)
   procedure FormCreate(Sender: TObject);
   procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    FRegistry: TogsVarRegistry;
    FCurrentSection: AnsiString;
    FFileName: String;

    // Вспомогательные методы
    procedure RefreshTree;
    procedure RefreshList;
    function NormalizeSectionPath(const S: AnsiString): AnsiString;
    function NodePath(Node: TTreeNode): AnsiString;
    function EnsureTreePath(const Path: AnsiString): TTreeNode;
    function PromptText(const ACaption, APrompt, ADefault: String): String;
    function ValueTypeToText(Vt: TogsRegValueType): String;
    function BuildFullKey(const SectionPath, name1: AnsiString): AnsiString;
    function SplitKey(const FullKey: AnsiString; out SectionPath, name1: AnsiString): Boolean;
    function SameTextA(const A, B: AnsiString): Boolean;

    // Работа с файлами
    procedure LoadFromFile(const FileName_: String);
    procedure SaveToFile(const FileName_: String);
    procedure CreateDefaultSections;

  published
    // Компоненты формы (объявлены в .frm файле)
    MainMenu: TMainMenu;
    FileMenu: TMenuItem;
    MiNew: TMenuItem;
    MiOpen: TMenuItem;
    MiSave: TMenuItem;
    MiSaveAs: TMenuItem;
    MiExit: TMenuItem;
    EditMenu: TMenuItem;
    MiAddSection: TMenuItem;
    MiAddValue: TMenuItem;
    MiEditValue: TMenuItem;
    MiDelete: TMenuItem;
    Tree: TTreeView;
    List: TListView;
    StatusBar: TStatusBar;
    Splitter: TSplitter;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    
    // Обработчики событий
//    procedure FormCreate(Sender: TObject);
//    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure DoNew(Sender: TObject);
    procedure DoOpen(Sender: TObject);
    procedure DoSave(Sender: TObject);
    procedure DoSaveAs(Sender: TObject);
    procedure DoExit(Sender: TObject);
    procedure DoAddSection(Sender: TObject);
    procedure DoAddValue(Sender: TObject);
    procedure DoEditValue(Sender: TObject);
    procedure DoDelete(Sender: TObject);
    procedure TreeChange(Sender: TObject; Node: TTreeNode);
    procedure TreeSelectionChanged(Sender: TObject);
    procedure ListDblClick(Sender: TObject);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  RegistryMainForm: TRegistryMainForm;

implementation

{$R *.frm}

{ TRegistryMainForm }

constructor TRegistryMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  // Создаем реестр
  FRegistry := TogsVarRegistry.Create;
  FCurrentSection := '';
  FFileName := '';
  
  // Настраиваем колонки в ListView
  List.Columns.Add.Caption := 'Имя';
  List.Columns.Add.Caption := 'Тип';
  List.Columns.Add.Caption := 'Значение';
  List.Columns[0].Width := 150;
  List.Columns[1].Width := 80;
  List.Columns[2].Width := 350;
  
  // Инициализация дерева
  Tree.Items.Clear;
  Tree.Items.Add(nil, 'ROOT').Expanded := True;
  
  RefreshTree;
  RefreshList;
end;

destructor TRegistryMainForm.Destroy;
begin
  FreeAndNil(FRegistry);
  inherited Destroy;
end;

{ Вспомогательные функции }

function TRegistryMainForm.SameTextA(const A, B: AnsiString): Boolean;
begin
  Result := AnsiCompareText(String(A), String(B)) = 0;
end;

function TRegistryMainForm.NormalizeSectionPath(const S: AnsiString): AnsiString;
var
  t: String;
begin
  t := String(S);
  t := StringReplace(t, '/', '\', [rfReplaceAll]);
  while (Length(t) > 0) and (t[1] = '\') do Delete(t, 1, 1);
  while (Length(t) > 0) and (t[Length(t)] = '\') do Delete(t, Length(t), 1);
  Result := AnsiString(t);
end;

function TRegistryMainForm.NodePath(Node: TTreeNode): AnsiString;
var
  parts: TStringList;
  n: TTreeNode;
  i: Integer;
  s: String;
begin
  Result := '';
  if Node = nil then Exit;

  parts := TStringList.Create;
  try
    n := Node;
    while (n <> nil) and (n.Parent <> nil) do
    begin
      parts.Add(n.Text);
      n := n.Parent;
    end;

    s := '';
    for i := parts.Count - 1 downto 0 do
    begin
      if s <> '' then s := s + '\';
      s := s + parts[i];
    end;
    Result := AnsiString(s);
  finally
    parts.Free;
  end;
end;

function TRegistryMainForm.EnsureTreePath(const Path: AnsiString): TTreeNode;
var
  p: String;
  sl: TStringList;
  i: Integer;
  cur: TTreeNode;
  child: TTreeNode;
  name1: String;
begin
  Result := nil;
  p := String(NormalizeSectionPath(Path));
  if p = '' then Exit(Tree.Items.GetFirstNode);

  sl := TStringList.Create;
  try
    sl.Delimiter := '\';
    sl.StrictDelimiter := True;
    sl.DelimitedText := p;

    cur := Tree.Items.GetFirstNode;
    if cur = nil then Exit;

    for i := 0 to sl.Count - 1 do
    begin
      name1 := sl[i];
      child := cur.GetFirstChild;
      while (child <> nil) and (not SameText(child.Text, name1)) do
        child := child.GetNextSibling;

      if child = nil then
        child := Tree.Items.AddChild(cur, name1);

      cur := child;
    end;

    Result := cur;
  finally
    sl.Free;
  end;
end;

function TRegistryMainForm.PromptText(const ACaption, APrompt, ADefault: String): String;
begin
  Result := ADefault;
  if not InputQuery(ACaption, APrompt, Result) then
    Result := '';
end;

function TRegistryMainForm.ValueTypeToText(Vt: TogsRegValueType): String;
begin
  case Vt of
    rvtNone: Result := 'None';
    rvtInt: Result := 'Int';
    rvtFloat: Result := 'Float';
    rvtBool: Result := 'Bool';
    rvtString: Result := 'String';
    rvtColor: Result := 'Color';
  else
    Result := 'Unknown';
  end;
end;

function TRegistryMainForm.BuildFullKey(const SectionPath, name1: AnsiString): AnsiString;
var
  sec: AnsiString;
begin
  sec := NormalizeSectionPath(SectionPath);
  if sec = '' then Result := name1
  else Result := sec + '\' + name1;
end;

function TRegistryMainForm.SplitKey(const FullKey: AnsiString; out SectionPath, name1: AnsiString): Boolean;
var
  s: String;
  p: SizeInt;
begin
  Result := False;
  s := String(FullKey);
  p := LastDelimiter('\', s);
  if p <= 0 then
  begin
    SectionPath := '';
    name1 := FullKey;
    Exit(True);
  end;
  SectionPath := AnsiString(Copy(s, 1, p - 1));
  name1 := AnsiString(Copy(s, p + 1, Length(s) - p));
  Result := True;
end;

{ Работа с файлами }

procedure TRegistryMainForm.LoadFromFile(const FileName_: String);
var
  st: TogsStream;
begin
  if not FileExists(FileName_) then
  begin
    // Создаём пустой реестр, если файла нет
    FRegistry.Clear;
    FFileName := FileName_;
    // Сразу сохраняем пустой реестр в новый файл
    SaveToFile(FileName_);
    Exit;
  end;

  // Если файл существует, загружаем его
  st := TogsStream.CreateFileStream(FileName_, fmOpenRead or fmShareDenyWrite, nil);
  try
    if st.Size > 0 then  // Проверяем, не пустой ли файл
      FRegistry.LoadFromStream(st)
    else
      FRegistry.Clear;  // Если файл пустой, создаём пустой реестр
      
    FFileName := FileName_;
  finally
    st.Free;
  end;
  
  RefreshTree;
  RefreshList;
end;

procedure TRegistryMainForm.SaveToFile(const FileName_: String);
var
  st: TogsStream;
begin
  st := TogsStream.CreateFileStream(FileName_, fmCreate or fmShareDenyWrite, nil);
  try
    FRegistry.SaveToStream(st);
    FFileName := FileName_;
  finally
    st.Free;
  end;
end;

{ Обработчики меню }

procedure TRegistryMainForm.DoNew(Sender: TObject);
begin
  FRegistry.Clear;
  FFileName := '';
  FCurrentSection := '';
  RefreshTree;
  RefreshList;
end;

procedure TRegistryMainForm.DoOpen(Sender: TObject);
begin
  if not OpenDialog.Execute then Exit;
  LoadFromFile(OpenDialog.FileName);
end;

procedure TRegistryMainForm.DoSave(Sender: TObject);
begin
  if FFileName = '' then
  begin
    DoSaveAs(Sender);
    Exit;
  end;
  SaveToFile(FFileName);
end;

procedure TRegistryMainForm.DoSaveAs(Sender: TObject);
begin
  if not SaveDialog.Execute then Exit;
  SaveToFile(SaveDialog.FileName);
end;

procedure TRegistryMainForm.DoExit(Sender: TObject);
begin
  Close;
end;

procedure TRegistryMainForm.DoAddSection(Sender: TObject);
var
  sec: String;
  cur: AnsiString;
  path: AnsiString;
  fullKey: AnsiString;
  newNode: TTreeNode;
begin
  cur := FCurrentSection;
  sec := PromptText('Добавить раздел', 'Имя/путь раздела', '');
  if sec = '' then Exit;

  path := NormalizeSectionPath(AnsiString(sec));
  if cur <> '' then
  begin
    fullKey := BuildFullKey(cur, AnsiString(sec));
    // Добавляем раздел как значение с пустым значением
    FRegistry.SetStr(fullKey, '');
  end
  else
  begin
    // Если это корневой раздел
    fullKey := NormalizeSectionPath(AnsiString(sec));
    FRegistry.SetStr(fullKey, '');
  end;

  // Обновляем дерево
  RefreshTree;
  
  // Находим и выбираем новый узел
  newNode := EnsureTreePath(path);
  if newNode <> nil then
  begin
    Tree.Selected := newNode;
    newNode.MakeVisible;
    // Обновляем текущий раздел и список
    FCurrentSection := NodePath(newNode);
    RefreshList;
  end;
end;

procedure TRegistryMainForm.DoAddValue(Sender: TObject);
var
  name1: String;
  v: String;
  vt: Integer;
  fullKey: AnsiString;
  i: Integer;
  f: Double;
  b: Boolean;
  c: Integer;
  selectedNode: TTreeNode;
  editForm: TValueEditForm;
begin
  name1 := '';
  v := '';
  vt := 4; // String по умолчанию
  
  editForm := TValueEditForm.Create(nil);
  try
    editForm.Caption := 'Добавить значение';
    editForm.EditName.Text := name1;
    editForm.EditValue.Text := v;
    editForm.RadioGroupType.ItemIndex := vt;
    
    if editForm.ShowModal <> mrOK then Exit;
    
    name1 := editForm.EditName.Text;
    v := editForm.EditValue.Text;
    vt := editForm.RadioGroupType.ItemIndex;
  finally
    editForm.Free;
  end;
  
  if name1 = '' then Exit;

  fullKey := BuildFullKey(FCurrentSection, AnsiString(name1));

  case TogsRegValueType(vt) of
    rvtNone: ;
    rvtInt: begin
      if not TryStrToInt(v, i) then i := 0;
      FRegistry.SetInt(fullKey, i);
    end;
    rvtFloat: begin
      if not TryStrToFloat(v, f) then f := 0;
      FRegistry.SetFloat(fullKey, f);
    end;
    rvtBool: begin
      b := (LowerCase(v) = '1') or (LowerCase(v) = 'true') or (LowerCase(v) = 'yes');
      FRegistry.SetBool(fullKey, b);
    end;
    rvtString: FRegistry.SetStr(fullKey, AnsiString(v));
    rvtColor: begin
      if not TryStrToInt(v, c) then c := 0;
      FRegistry.SetColor(fullKey, TColor(c));
    end;
  end;

  // Сохраняем текущий выбранный узел
  selectedNode := Tree.Selected;
  
  // Обновляем дерево и список
  RefreshTree;
  RefreshList;
  
  // Восстанавливаем выбор узла
  if selectedNode <> nil then
  begin
    // Ищем узел с тем же путем
    selectedNode := EnsureTreePath(FCurrentSection);
    if selectedNode <> nil then
      Tree.Selected := selectedNode;
  end;
end;

procedure TRegistryMainForm.DoEditValue(Sender: TObject);
var
  name1: String;
  item: TListItem;
  fullKey: AnsiString;
  v: String;
  vt: Integer;
  i: Integer;
  f: Double;
  b: Boolean;
  c: Integer;
  regItem: TogsRegItem;
  editForm: TValueEditForm;
begin
  if List.Selected = nil then Exit;
  item := List.Selected;
  name1 := item.Caption;
  fullKey := BuildFullKey(FCurrentSection, AnsiString(name1));

  vt := 4; // String по умолчанию
  regItem := FRegistry.GetItem(fullKey);
  if regItem <> nil then vt := Ord(regItem.ValueType);

  // Получаем текущее значение
  case TogsRegValueType(vt) of
    rvtNone: v := '';
    rvtInt: v := IntToStr(regItem.GetInt(0));
    rvtFloat: v := FloatToStr(regItem.GetFloat(0));
    rvtBool: if regItem.GetBool(False) then v := 'true' else v := 'false';
    rvtString: v := String(regItem.GetStr(''));
    rvtColor: v := IntToStr(Integer(regItem.GetColor(0)));
  else
    v := '';
  end;

  editForm := TValueEditForm.Create(nil);
  try
    editForm.Caption := 'Изменить значение';
    editForm.EditName.Text := name1;
    editForm.EditValue.Text := v;
    editForm.RadioGroupType.ItemIndex := vt;
    
    if editForm.ShowModal <> mrOK then Exit;
    
    name1 := editForm.EditName.Text;
    v := editForm.EditValue.Text;
    vt := editForm.RadioGroupType.ItemIndex;
  finally
    editForm.Free;
  end;

  case TogsRegValueType(vt) of
    rvtNone: begin
      FRegistry.Delete(fullKey);
    end;
    rvtInt: begin
      if not TryStrToInt(v, i) then i := 0;
      FRegistry.SetInt(fullKey, i);
    end;
    rvtFloat: begin
      if not TryStrToFloat(v, f) then f := 0;
      FRegistry.SetFloat(fullKey, f);
    end;
    rvtBool: begin
      b := (LowerCase(v) = '1') or (LowerCase(v) = 'true') or (LowerCase(v) = 'yes');
      FRegistry.SetBool(fullKey, b);
    end;
    rvtString: FRegistry.SetStr(fullKey, AnsiString(v));
    rvtColor: begin
      if not TryStrToInt(v, c) then c := 0;
      FRegistry.SetColor(fullKey, TColor(c));
    end;
  end;

  RefreshTree;
  RefreshList;
end;

procedure TRegistryMainForm.DoDelete(Sender: TObject);
var
  fullKey: AnsiString;
  name1: AnsiString;
  sec: AnsiString;
  prefix: AnsiString;
begin
  if (List.Selected <> nil) then
  begin
    name1 := AnsiString(List.Selected.Caption);
    fullKey := BuildFullKey(FCurrentSection, name1);
    FRegistry.Delete(fullKey);
    RefreshTree;
    RefreshList;
    Exit;
  end;

  if (Tree.Selected <> nil) and (Tree.Selected.Parent <> nil) then
  begin
    sec := NodePath(Tree.Selected);
    if MessageDlg('Удалить раздел?', String(sec), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

    prefix := NormalizeSectionPath(sec);
    if prefix <> '' then
    begin
      prefix := prefix + '\';
      FRegistry.DeleteByPrefix(prefix);
      RefreshTree;
      RefreshList;
    end;

  end;
end;

procedure TRegistryMainForm.TreeChange(Sender: TObject; Node: TTreeNode);
begin

end;

{ Обработчики событий компонентов }

procedure TRegistryMainForm.TreeSelectionChanged(Sender: TObject);
begin
  if Tree.Selected = nil then Exit;
  if Tree.Selected.Parent = nil then FCurrentSection := ''
  else FCurrentSection := NodePath(Tree.Selected);
  RefreshList;
end;

procedure TRegistryMainForm.ListDblClick(Sender: TObject);
begin
  DoEditValue(Sender);
end;

{ Обновление отображения }

procedure TRegistryMainForm.FormCreate(Sender: TObject);
begin
  FRegistry := TogsVarRegistry.Create;
  FCurrentSection := '';
  FFileName := DEFAULT_REGISTRY_FILE;
  
  // Загружаем реестр из файла по умолчанию
  LoadFromFile(FFileName);
  
  // Создаем начальные секции, если их нет
  CreateDefaultSections;
  
  // Инициализируем интерфейс
  RefreshTree;
  RefreshList;
end;

procedure TRegistryMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // Автосохранение при закрытии
  if (FFileName <> '') and (FRegistry.Count > 0) then
  begin
    try
      SaveToFile(FFileName);
    except
      // Если не удалось сохранить, просто закрываем форму
      // Можно добавить сообщение об ошибке, но не обязательно
    end;
  end;
  
  // Освобождаем ресурсы
  FRegistry.Free;
end;

procedure TRegistryMainForm.CreateDefaultSections;
var
  sections: array of String;
  i: Integer;
  sectionKey: AnsiString;
begin
  // Определяем секции по умолчанию
  SetLength(sections, 3);
  sections[0] := 'MathVars';
  sections[1] := 'MapSettings';
  sections[2] := 'Environment';
  
  // Создаем секции, если они еще не существуют
  for i := 0 to High(sections) do
  begin
    sectionKey := NormalizeSectionPath(AnsiString(sections[i]));
    // Проверяем, существует ли уже секция
    if FRegistry.GetItem(sectionKey) = nil then
    begin
      // Создаем секцию как пустое строковое значение
      FRegistry.SetStr(sectionKey, '');
    end;
  end;
end;

procedure TRegistryMainForm.RefreshTree;
var
  i: Integer;
  sec, name1: AnsiString;
  root: TTreeNode;
  item: TogsRegItem;
begin
  Tree.Items.BeginUpdate;
  try
    Tree.Items.Clear;
    root := Tree.Items.Add(nil, 'ROOT');
    root.Expanded := True;

    for i := 0 to FRegistry.Count - 1 do
    begin
      item := FRegistry.Items[i];
      if not SplitKey(item.Key, sec, name1) then Continue;
      
      // Создаем путь для раздела
      EnsureTreePath(sec);
      
      // Если это раздел (пустое строковое значение), добавляем его как узел
      if (item.ValueType = rvtString) and (item.GetStr('') = '') and (name1 <> '') then
      begin
        EnsureTreePath(item.Key);
      end;
    end;

    Tree.Selected := root;
  finally
    Tree.Items.EndUpdate;
  end;
end;

procedure TRegistryMainForm.RefreshList;
var
  i: Integer;
  sec, name1: AnsiString;
  li: TListItem;
  vt: TogsRegValueType;
  valText: String;
  item: TogsRegItem;
begin
  List.Items.BeginUpdate;
  try
    List.Items.Clear;

    for i := 0 to FRegistry.Count - 1 do
    begin
      item := FRegistry.Items[i];
      if not SplitKey(item.Key, sec, name1) then Continue;
      if not SameTextA(NormalizeSectionPath(sec), NormalizeSectionPath(FCurrentSection)) then Continue;
      
      // Пропускаем разделы (пустые строковые значения)
      if (item.ValueType = rvtString) and (item.GetStr('') = '') then Continue;

      vt := item.ValueType;
      case vt of
        rvtNone: valText := '';
        rvtInt: valText := IntToStr(item.GetInt(0));
        rvtFloat: valText := FloatToStr(item.GetFloat(0));
        rvtBool: if item.GetBool(False) then valText := 'true' else valText := 'false';
        rvtString: valText := String(item.GetStr(''));
        rvtColor: valText := IntToStr(Integer(item.GetColor(0)));
      else
        valText := '';
      end;

      li := List.Items.Add;
      li.Caption := String(name1);
      li.SubItems.Add(ValueTypeToText(vt));
      li.SubItems.Add(valText);
    end;

    StatusBar.SimpleText := 'Count=' + IntToStr(FRegistry.Count) + ' Section=' + String(FCurrentSection);
  finally
    List.Items.EndUpdate;
  end;
end;

end.
