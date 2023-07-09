program main;
{$mode objfpc}{$H+}
{$scopedenums on}

uses web, sysutils, snaketypes, snake;

type GameStatus = (Running, Paused, GameOver);

var 
    canvas: TJSHTMLCanvasElement;
    shadow: TJSHTMLCanvasElement;

    ctx: TJSCanvasRenderingContext2D;
    snek: Snake.Snake;
    directions: DirectionsType;
    backgroundImage: TJSHTMLImageElement;
    status: GameStatus = GameStatus.Paused;
    currentFood: PositionType;

procedure AnimateDeath(ctx: TJSCanvasRenderingContext2D; positions: PositionList);
procedure render(pos: PositionType; index: Integer; delta: Integer);
    begin
      ctx.fillStyle := Format('rgb(%d,0,%d)', [255 - index * delta, 255 - index * delta]);
      ctx.fillRect(17 + pos.x * 24, 17 + pos.y * 24, 22, 22);
    end;
    procedure renderHead(pos: PositionType);
    begin
      ctx.fillStyle := 'yellow';
      ctx.fillRect(17 + pos.x * 24, 17 + pos.y * 24, 22, 22);
    end;
    var position: PositionType;
    var index: Integer;
begin
    index := 0;
    for position in positions do begin
        if index = 0 then begin
            renderHead(position);
            inc(index);
        end else begin
            render(position, index, (255 - 55) div positions.Count);
            inc(index);
        end;
        
    end;
  
end;
procedure DrawSnake(ctx: TJSCanvasRenderingContext2D; positions: PositionList);
    procedure render(pos: PositionType; index: Integer; delta: Integer);
    begin
      ctx.fillStyle := Format('rgb(%d,0,0)', [255 - index * delta]);
      ctx.fillRect(17 + pos.x * 24, 17 + pos.y * 24, 22, 22);
    end;
    procedure renderHead(pos: PositionType);
    begin
      ctx.fillStyle := 'green';
      ctx.fillRect(17 + pos.x * 24, 17 + pos.y * 24, 22, 22);
    end;
    var position: PositionType;
    var index: Integer;
begin
    index := 0;
    for position in positions do begin
        if index = 0 then begin
            renderHead(position);
            inc(index);
        end else begin
            render(position, index, (255 - 55) div positions.Count);
            inc(index);
        end;
        
        //WriteLn(position.x, ' - ', position.y);
    end;
end;

procedure MoveAndDraw(snek: Snake.Snake; ctx: TJSCanvasRenderingContext2d; directions: DirectionsType);
var positions: PositionList;
var oldPositions: PositionList;
begin
    oldPositions := snek.GetPositions();
    snek.Move(directions);
    if snek.isAlive then begin
        positions := snek.GetPositions();
        DrawSnake(ctx, positions);  
    end else begin
      AnimateDeath(ctx, oldPositions);
    end;
    
end;
procedure DrawFood(ctx: TJSCanvasRenderingContext2d; currentFood: PositionType);
begin
    ctx.fillStyle := 'lightsteelblue';
    ctx.fillRect(17 + currentFood.x * 24, 17 + currentFood.y * 24, 22, 22);
end;

procedure DrawField(ctx: TJSCanvasRenderingContext2D);
begin
    ctx.drawImage(backgroundImage, 0, 0);
end;

procedure SetUpField(ctx: TJSCanvasRenderingContext2D);
var i, j: Integer;
begin
    ctx.fillStyle := 'black';
    ctx.fillRect(0, 0, 512, 512);
    ctx.fillStyle := 'white';
    // 512-480 = 32
    ctx.fillRect(16, 16, 480, 480);
    {
        480 / 20 = 24
        starting 10, 10
    }
    ctx.fillStyle := '#aaa';
    for i := 0 to 19 do begin
        for j := 0 to 19 do begin
        ctx.beginPath(); {column}
        ctx.moveTo(16 + j * 24,           16 + i * 24); {origin}
        ctx.lineTo(16 + j * 24 + 24,      16 + i * 24); {top right}
        ctx.lineTo(16 + j * 24 + 24,      16 + i * 24 + 24); {bottom right}
        ctx.lineTo(16 + j * 24,           16 + i * 24 + 24); {bottom left}
        ctx.lineTo(16 + j * 24,           16 + i * 24); {origin}
        ctx.stroke();     
        end;
    end;
    backgroundImage := TJSHTMLImageElement.new(512, 512);
    backgroundImage.src := canvas.toDataURL();
end;

function isOppositeDirection(direction1, direction2: DirectionType): Boolean;
begin
  Result := false;
  case direction1 of
    DirectionType.Left: Result := (direction2 = DirectionType.Right);
    DirectionType.Right: Result := (direction2 = DirectionType.Left);
    DirectionType.Up: Result := (direction2 = DirectionType.Down);
    DirectionType.Down: Result := (direction2 = DirectionType.Up);
  end;
end;

function OnSwipe(event: TJSUIEvent): Boolean;
var direction: String;
    x, y: Integer;
    swipeDirection: DirectionType;
function setDirection(x, y: Integer; direction: DirectionType): Boolean;
var key: String;
begin
    if status = GameStatus.Running then begin
        key := Format('%d-%d', [x,y]);
        if directions.ContainsKey(key) then begin
        directions[key] := direction;
        end else begin
            directions.Add(key, direction);
        end;
        exit;
    end;
end;
begin
asm
direction = event.detail.dir;
end;
case direction of 
    'left': swipeDirection := DirectionType.Left;
    'right': swipeDirection := DirectionType.Right;
    'up': swipeDirection := DirectionType.Up;
    'down': swipeDirection := DirectionType.Down;
end;

    x := snek.head.position.x;
    y := snek.head.position.y;
    if not isOppositeDirection(snek.head.direction, swipeDirection) then
    begin
        setDirection(x, y, swipeDirection);
    end;

    if (status = GameStatus.Paused) then begin
        status := GameStatus.Running;
    end;
  Result := True;
end;

function OnKeyUp(event: TJSKeyBoardEvent): Boolean;
var x: Integer;
var y: Integer;
function setDirection(x, y: Integer; direction: DirectionType): Boolean;
var key: String;
begin
    if status = GameStatus.Running then begin
        key := Format('%d-%d', [x,y]);
        if directions.ContainsKey(key) then begin
        directions[key] := direction;
        end else begin
            directions.Add(key, direction);
        end;
        exit;
    end;
end;
begin
    //WriteLn('>>>' + event.key);
    x := snek.head.position.x;
    y := snek.head.position.y;
    case event.key of 
        'Escape': begin
            if status = GameStatus.Running then begin
                status := GameStatus.Paused;
            end else begin
                status := GameStatus.Running;
            end;
        end;
        'ArrowUp': begin
            if snek.head.direction <> DirectionType.Down then
                setDirection(x, y, DirectionType.Up);
        end;
        'ArrowDown': begin
        if snek.head.direction <> DirectionType.Up then
            setDirection(x, y, DirectionType.Down);
        end;
        'ArrowLeft': begin
        if snek.head.direction <> DirectionType.Right then
            setDirection(x, y, DirectionType.Left);
        end;
        'ArrowRight': begin
        if snek.head.direction <> DirectionType.Left then
            setDirection(x, y, DirectionType.Right);
        end;
    end;
    if (event.key <> 'Escape') and (status = GameStatus.Paused) then begin
        status := GameStatus.Running;
    end;
    Result := True;
end;

function NotInSnake(x, y: Integer): Boolean;
var pos: PositionType;
begin
    Result := True;
    for pos in snek.GetPositions() do begin
        if (pos.x = x) and (pos.y = y) then begin
            Result := False;
            exit;
        end;
    end;
end;

function SpawnFood(): PositionType;
var x, y: Integer;

begin
    repeat begin
        x := Random(20);
        y := Random(20);
    end until NotInSnake(x, y);
    Result.x := x;
    Result.y := y;
end;

procedure PauseScreen(ctx: TJSCanvasRenderingContext2D);
begin
    ctx.fillStyle := 'rgba(0,0,0,0.5)';
    ctx.fillRect(0, 0, 512, 512);
    ctx.fillStyle := 'white';
    ctx.font := '30px Arial';
    ctx.fillText('- Paused - ', 180, 200);
    ctx.fillText('Press a key or swipe to resume', 50, 300);
end;

procedure StartNewGame();
begin
    // Randomize; not needed for web.
    snek := Snake.Snake.Create();
    snek.Grow(); // start at size 2
    currentFood := SpawnFood();
end;

procedure copyToSecondCanvas();
var image: TJSHTMLImageElement;
    ctx2: TJSCanvasRenderingContext2D;
    function OnImageLoad(event: TJSEvent): Boolean;
    begin
      ctx2 := TJSCanvasRenderingContext2D(shadow.getContext('2d'));
      ctx2.drawImage(image, 0, 0);
      Result := True;
    end;
begin
    
    image := TJSHTMLImageElement.new(512, 512);
    image.onload := @OnImageLoad;
    image.src := canvas.toDataURL('image/bmp');
end;

begin
    canvas := TJSHTMLCanvasElement(document.getElementById('field'));
    shadow := TJSHTMLCanvasElement(document.getElementById('shadow'));
    document.onkeyup := @OnKeyUp;   
    document.addEventListener('swiped', @OnSwipe);
    ctx := TJSCanvasRenderingContext2D(canvas.getContext('2d'));
    directions := DirectionsType.Create();
    StartNewGame();

    document.getElementById('restart').addEventListener('click', procedure begin
        StartNewGame();
        status := GameStatus.Paused;
    end);

    document.getElementById('pause').addEventListener('click', procedure begin
        if snek.isAlive() then begin
            if status = GameStatus.Running then begin
                status := GameStatus.Paused;
            end else begin
                status := GameStatus.Running;
            end;
        end;
    end);

    SetUpField(ctx);
    
    window.setInterval(procedure begin 
        if status = GameStatus.Running then begin
            
            if (snek.isAlive()) then begin
                DrawField(ctx);            
                if (NotInSnake(currentFood.x, currentFood.y)) then begin
                    
                    DrawFood(ctx, currentFood);
                    
                end else begin
                    snek.Grow();
                    currentFood := SpawnFood();
                    DrawFood(ctx, currentFood);
                end;
                
                moveAndDraw(snek, ctx, directions);
                //copyToSecondCanvas();
            end;
        end else begin
            PauseScreen(ctx);
        end;
    end, 128); // 60fps = 16ms
    

end.