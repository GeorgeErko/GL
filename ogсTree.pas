unit ogcTree;

{$mode ObjFPC}{$H+}

interface

uses Classes, SysUtils, ogcBasic, AVL_Tree;

{ TogsTree }

type
 TogsTree = class(TogsBasic)
 private
   OnCompareMethod: TListSortCompare;
 protected
   avlTree: TavlTree;
   List: TList;
 public
   constructor Create(OnCompareMethod_: TListSortCompare = nil);
   destructor Destroy;override;
  //
   function Add(Item_: TogsBasic): boolean;
   function Remove(Item_: TogsBasic): boolean;
  //
   function FindItem(Item_: TogsBasic): TogsBasic;
 end;


implementation

{ TogsTree }

constructor TogsTree.Create(OnCompareMethod_: TListSortCompare);
begin
 if OnCompareMethod_ = nil then
  avlTree := TAvlTree.Create(OnCompareMethod) else
  avlTree := TAvlTree.Create(ogsListSortCompare);
 List := TList.Create;
end;

destructor TogsTree.Destroy;
begin
 avlTree.Free; // уничтожение объектов в дереве
 List.Free;
end;

function TogsTree.Add(Item_: TogsBase): boolean;
begin
 avlTree.Add(Item_);
 List.Add(Item_);
end;

function TogsTree.Remove(Item_: TogsBase): boolean;
begin
 avlTree.Remove(Item_);
 Index := List.IndexOf(Item_);
 If Index <> -1 then List.Delete(Index);
end;

function TogsTree.FindItem(Item_: ToghBase): ToghBase;
var Node: TAVLTreeNode;
begin
 Result := nil;
 Node := avlTree.Find(Item_);
 If Node <> nil then Result := Node.Data;
end;

end.

