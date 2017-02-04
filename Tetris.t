

% Tetris Game by Yu


% ========== Description ==========
% One player Tetris game.
% Tiles arranged into random shape falling down to build a tower
% Move the shape left, right, down, or rotate it by pressing the arrow keys
% Game is over when the tower reaches top
% A row disappears when it's filled
%
% This is a procedure-based program structure. No functions or objects are involved

% -- Turing version 4.1.1 (Not tested but should also work in 4.1)
% -- -> Draw module
% -- -> View module
% -- -> Rand module
% -- -> Input module

% ================
%    Constants
% ================

% Sets the size and positioning of the game

const ROWS : int := 20

const COLUMNS : int := 10

const BLOCK_WIDTH : int := 20

const PADDING : int := 24

const SCREEN_WIDTH : int := COLUMNS * BLOCK_WIDTH + 2 * PADDING

const SCREEN_HEIGHT : int := ROWS * BLOCK_WIDTH + 2 * PADDING

const SETUP : string := "graphics:" + intstr (SCREEN_WIDTH) + "," + intstr (SCREEN_HEIGHT) + "; offscreenonly; nobuttonbar; title: Tetris"

% Sets the speed of the gameplay (i.e. the delay between each time the tetromino goes down)

const DELAY_MILSECS : int := 1000

% Stores information about the various tetrominoes
% Uses 16 bit number to represent the 7 tetrominoes in all 4 orientations, on 4 by 4 grid
% Details as follows:

%I - 0100 0100 0100 0100, 0000 1111 0000 0000, 0010 0010 0010 0010, 0000 0000 1111 0000
%O - 0000 0110 0110 0000, 0000 0110 0110 0000, 0000 0110 0110 0000, 0000 0110 0110 0000
%S - 0000 0000 0110 1100, 0000 1000 1100 0100, 0000 0110 1100 0000, 0000 0100 0110 0010
%Z - 0000 0000 1100 0110, 0000 0100 1100 1000, 0000 1100 0110 0000, 0000 0010 0110 0100
%J - 0000 0100 0100 1100, 0000 1000 1110 0000, 0000 0110 0100 0100, 0000 0000 1110 0010
%L - 0000 0100 0100 0110, 0000 0000 1110 1000, 0000 1100 0100 0100, 0000 0010 1110 0000
%T - 0000 0000 1110 0100, 0000 0100 1100 0100, 0000 0100 1110 0000, 0000 0100 0110 0100

const TOTAL_TILES : int := 7

const BINARY_TILES : array 0 .. TOTAL_TILES - 1, 0 .. 3 of int := init

    (

    17476, 3840, 8738, 240,

    1632, 1632, 1632, 1632,

    108, 2244, 1728, 1122,

    198, 1224, 3168, 612,

    1100, 2272, 1604, 226,

    1094, 232, 3140, 736,

    228, 1220, 1248, 1124

    )

const COLOUR_SCHEME : array 0 .. TOTAL_TILES - 1 of int := init (cyan, yellow, green, red, blue, brown, magenta)


% ================
%    Variables
% ================


% grid is a 2 dimensional array of size ROWS * COLUMNS
% Each value represents one tilespace in the form of an integer
% If the value is 0 it means the tilespace is empty
% Otherwise the integer represent the colour of the tile in the space

var grid : array 0 .. ROWS - 1, 0 .. COLUMNS - 1 of int

% 'falling' stores value for the fallinging tiles
% 'suspect' suspect tests actions to avoid collision

var falling, suspect : array 0 .. 15 of

    record

	row : int
	column : int
	value : int

    end record

% Variable stores the next shape to be displayed

var currentID, nextID, currentRotation : int

% Part of the suspect test: If ok then proceed is true
% Used as part of the timing

var proceed, stop : boolean


% ================
%    Procedures
% ================


% Resets all the tiles in the falling and suspect array to empty and colour black

proc resetTiles ()

    for i : 0 .. 15

	falling (i).value := 0
	suspect (i).value := 0

    end for

end resetTiles


% Draw a square tile in the grid, given the row, column, and colour

proc drawTile (row, column, col : int, falling : boolean)

    var x : int := column * BLOCK_WIDTH + PADDING

    var y : int := row * BLOCK_WIDTH + PADDING

    drawfillbox (x + 2, y + 2, x + BLOCK_WIDTH - 2, y + BLOCK_WIDTH - 2, col)

    if falling then

	drawbox (x + 2, y + 2, x + BLOCK_WIDTH - 2, y + BLOCK_WIDTH - 2, 0)

    end if

end drawTile


% Draws everything needed onto the screen, including the static and fallinging tiles

proc drawScreen ()

    % Draws the black background

    drawfillbox (PADDING - 2, PADDING - 2, SCREEN_WIDTH - PADDING + 2, SCREEN_HEIGHT - PADDING + 2, 7)

    % Draws all the spaces

    for i : 0 .. ROWS - 1

	for j : 0 .. COLUMNS - 1

	    % Checks if the grid space is empty

	    if grid (i, j) > 0 then

		drawTile (i, j, grid (i, j), false)

	    end if

	end for

    end for

    % Draws the fallinging tiles

    for k : 0 .. 15

	% Excludes the empty and out of bounds tiles

	if falling (k).value > 0 and falling (k).row < ROWS then

	    drawTile (falling (k).row, falling (k).column, falling (k).value, true)

	end if

    end for

    % Copies the image from the off-screen buffer

    View.Update ()

end drawScreen


% Insert the array value of a tetromino, given an id, rotation, and coordinates
% Right now it has to copy suspect back to falling because there is not game over detection yet

proc setTetro (id, rotation, x, y : int)

    var number : int := BINARY_TILES (id, rotation)

    for row : 0 .. 3

	for column : 0 .. 3

	    suspect (4 * row + column).row := y + row
	    suspect (4 * row + column).column := x + column

	    if not (number and 1 shl (4 * row + column)) = 0 then

		suspect (4 * row + column).value := COLOUR_SCHEME (id)

	    end if

	end for

    end for

    % Temporarily copy back

    for i : 0 .. 15

	falling (i).row := suspect (i).row
	falling (i).column := suspect (i).column
	falling (i).value := suspect (i).value

    end for

end setTetro


% Generates a new tile shape

proc newTetro ()

    % Resets the current falling array

    resetTiles ()

    currentRotation := Rand.Int (0, 3)

    % Copy next into falling/ No Rotations for now

    setTetro (nextID, currentRotation, Rand.Int (0, COLUMNS - 4), ROWS - 4)

    % Plan for the new shape
    currentID := nextID
    nextID := Rand.Int (0, TOTAL_TILES - 1)

end newTetro


% 'initialize' must be called for the program to work
% Otherwise the program will say 'Variable has no value'

proc initialize ()

    % Set screen to 340 * 480 and draw the backgound
    % Also set to manually update from off-screen buffer to prevent flickers

    setscreen (SETUP)

    drawfillbox (0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, darkgrey)

    % Initialize the grid array by assigning 0 to each of them

    for i : 0 .. ROWS - 1

	for j : 0 .. COLUMNS - 1

	    grid (i, j) := 0

	end for


    end for

    stop := false

    % Call the reset procedure to also initialize 'falling'

    nextID := Rand.Int (0, TOTAL_TILES - 1)

    resetTiles ()
    newTetro ()

end initialize


% Copies all the values of falling into suspect

proc copyTiles ()

    for i : 0 .. 15
	suspect (i).row := falling (i).row
	suspect (i).column := falling (i).column
	suspect (i).value := falling (i).value
    end for

end copyTiles


% Tests for tile and border collisions
% Copies tiles back to falling if ok, otherwise just return

proc update ()

    proceed := true

    for i : 0 .. 15

	if suspect (i).value > 0 and (
		suspect (i).row < 0
		or suspect (i).row >= ROWS
		or suspect (i).column < 0
		or suspect (i).column >= COLUMNS
		or grid (suspect (i).row, suspect (i).column) > 0)
		then

	    proceed := false

	end if

    end for

    if proceed then

	for i : 0 .. 15

	    falling (i).row := suspect (i).row
	    falling (i).column := suspect (i).column
	    falling (i).value := suspect (i).value

	end for

    end if

    drawScreen ()

end update


% Stop the tetro from moving and add it to the grid array

proc stopTetro ()

    for j : 0 .. 15

	if falling (j).value > 0 then

	    grid (falling (j).row, falling (j).column) := falling (j).value

	end if

    end for


    % Get the next tetromino moving

    newTetro ()

    % Will replace update when game overs are available

    drawScreen ()

end stopTetro


% Move the fallinging tile one space to the left or does nothing if not possible

proc moveLeft ()

    copyTiles ()

    for i : 0 .. 15

	suspect (i).column := suspect (i).column - 1

    end for

    update ()

end moveLeft


% Move the fallinging tile one space to the right or does nothing if not possible

proc moveRight ()

    copyTiles ()

    for i : 0 .. 15

	suspect (i).column := suspect (i).column + 1

    end for

    update ()

end moveRight


% Move the fallinging tile one space down
% If that is not possible, stop and spawn a new shape

proc moveDown ()

    copyTiles ()

    for i : 0 .. 15

	suspect (i).row := suspect (i).row - 1

    end for

    update ()

    % Stop the tiles from going and spawn a new shape

    if not proceed then

	stopTetro ()

    end if

end moveDown


% Rotate the shape by 90 degrees clockwise

proc rotate ()

    currentRotation += 1

    if currentRotation > 3 then

	currentRotation := 0

    end if

    resetTiles ()
    setTetro (currentID, currentRotation, falling (0).column, falling (0).row)

    update ()

end rotate


% ================
%    Processes
% ================

process detectKeys ()

    var keydown : array char of boolean

    % These variables are here to make sure that the keystroke
    % event is not triggered again until the user has released
    % the key.

    var leftarrow : boolean := false
    var rightarrow : boolean := false
    var downarrow : boolean := false
    var uparrow : boolean := false

    loop

	% Get all the current keys being pressed down

	Input.KeyDown (keydown)

	if keydown (KEY_LEFT_ARROW) then

	    if not leftarrow then
		moveLeft ()
	    end if

	    leftarrow := true

	elsif keydown (KEY_RIGHT_ARROW) then

	    if not rightarrow then
		moveRight ()
	    end if

	    rightarrow := true

	elsif keydown (KEY_DOWN_ARROW) then

	    if not downarrow then
		moveDown ()
		drawScreen ()
	    end if

	    downarrow := true

	elsif keydown (KEY_UP_ARROW) then

	    if not uparrow then
		rotate ()
	    end if

	    uparrow := true

	elsif keydown (KEY_ESC) then

	    stop := true
	    return

	else

	    % Reset the arrows variables because the user is not holding down the button

	    leftarrow := false
	    rightarrow := false
	    downarrow := false
	    uparrow := false

	end if

	% Set keystroke detection rate to 25 per second

	delay (40)

    end loop

end detectKeys


% ================
%   Main Program
% ================


initialize ()


% Fork the Key Detection Loop

fork detectKeys ()


% Main Loop

loop

    moveDown ()

    delay (DELAY_MILSECS)

    exit when stop

end loop
