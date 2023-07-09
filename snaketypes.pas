unit snaketypes;
{$mode objfpc}{$H+}{$scopedenums on}

interface
uses Generics.Collections;

type DirectionType = (Up, Down, Left, Right);

type PositionType = record
    x: Integer;
    y: Integer;
end;

type PositionList = specialize TList<PositionType>;

type NodeType = record
    position: PositionType;
    direction: DirectionType;
    next: ^NodeType;
end;

type DirectionsType = specialize TObjectDictionary<string, DirectionType>;

implementation

end.