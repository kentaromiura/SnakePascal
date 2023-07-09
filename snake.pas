unit snake;
{$mode objfpc}{$H+}


interface
uses snaketypes, sysutils;

type SnakeStatus = (Alive, Dead);

type Snake = class
    head: NodeType;
    
    constructor Create;
    destructor Destroy; override;
    
    function GetPositions(): PositionList;
    function isAlive(): Boolean;

    procedure Grow();
    procedure Move(directions: DirectionsType);
    procedure Kill();
    
    private 
        tail: ^NodeType;
        status: SnakeStatus;
    function isOutOfBounds(position: PositionType): Boolean;
end;

{
    snake will be a linked list from head to tail
    head will be the first node
    tail will be the last node
    each node will have a pointer to the next node
    movements are a map of [xy] position to a direction (up, down, left, right), 
    when the snake moves, all nodes moves in the direction they are facing,
    all node changes direction when in the xy position if there's a map entry for it
    and the tail remove the direction when it passes through it,

    when the snake eats a new tail is added and the link is updated

}

{module exports here}
implementation

constructor Snake.Create;
const initialPosition: PositionType = (
    x: 9;
    y: 9;
);
begin
  inherited;
  with head do begin
    position := initialPosition;
    direction := DirectionType.Right;
    next := Nil;
  end;
    tail := @head;
    status := SnakeStatus.Alive;
end;

function Snake.GetPositions(): PositionList;
var positions: PositionList;
var current : ^NodeType;
begin
    positions := PositionList.Create;
    current := @head;
    while current <> Nil do begin
        positions.Add(current^.position);
        current := current^.next;
    end;
    {return a list of positions}
    
    Result := positions;
end;

function Snake.isAlive(): Boolean;
begin
    Result := status = SnakeStatus.Alive;
end;

function Snake.isOutOfBounds(position: PositionType): Boolean;
begin
    Result := false;
    if (position.x < 0) or (position.y < 0) then Result := true;
    if (position.x > 19) or (position.y > 19) then Result := true;
end;

procedure Snake.Move(directions: DirectionsType);
var current : ^NodeType;
var nextDirection: DirectionType;
var key: string;
begin
    current := @head;
    
    if status = SnakeStatus.Alive then begin
        while current <> Nil do begin
            key := Format('%d-%d', [current^.position.x, current^.position.y]);
            if directions.ContainsKey(key) then begin
                current^.direction := directions[key];
                if current^.next = Nil then begin
                    // if tail, remove the direction
                    directions.Remove(key);
                end;
            end;
            case current^.direction of
                DirectionType.Up: current^.position.y := current^.position.y - 1;
                DirectionType.Down: current^.position.y := current^.position.y + 1;
                DirectionType.Left: current^.position.x := current^.position.x - 1;
                DirectionType.Right: current^.position.x := current^.position.x + 1;
            end;
            if isOutOfBounds(current^.position) then begin
                Kill();
            end;
            if current^ <> head then begin
                if (current^.position.x = head.position.x) and (current^.position.y = head.position.y) then begin
                    Kill();
                end;
            end;
            current := current^.next;
        end;
    end;
end;

procedure Snake.Grow();
var newPosition: PositionType;
var next: ^NodeType;

begin
    newPosition := tail^.position;

    case tail^.direction of
        DirectionType.Up: newPosition.y := newPosition.y + 1;
        DirectionType.Down: newPosition.y := newPosition.y - 1;
        DirectionType.Left: newPosition.x := newPosition.x + 1;
        DirectionType.Right: newPosition.x := newPosition.x - 1;
    end;
    New(next);
    tail^.next := next;
    
    with next^ do begin
        position := newPosition;
        direction := tail^.direction;
        next := Nil;
    end;

    tail := next;
end;

procedure Snake.Kill();
begin
    status := SnakeStatus.Dead;
end;

destructor Snake.Destroy;
begin
  {maybe free all nodes}
  inherited;
end;
{module code here}
end.