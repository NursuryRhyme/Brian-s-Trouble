// CSCB58 Winter 2018 Final Project
// Bubble Trouble Knockoff
// Names: Jeffrey So, Ricky Chen, Byron Leung, Brandon Shewnarain
// Description: Insert Description Here

`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

`define SCREEN_W 8'd160
`define SCREEN_H 7'd121
`define PLAYER_WIDTH 2'd3
`define PLAYER_SIZE `PLAYER_WIDTH * `PLAYER_WIDTH
`define PLAYER_COLOR 3'b111

module project
    (
        CLOCK_50,                       //  On Board 50 MHz
        // Your inputs and outputs here
        KEY,
        SW,
        LEDR,
        HEX0,
        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,                        //  VGA Clock
        VGA_HS,                         //  VGA H_SYNC
        VGA_VS,                         //  VGA V_SYNC
        VGA_BLANK_N,                        //  VGA BLANK
        VGA_SYNC_N,                     //  VGA SYNC
        VGA_R,                          //  VGA Red[9:0]
        VGA_G,                          //  VGA Green[9:0]
        VGA_B                           //  VGA Blue[9:0]
    );

    input           CLOCK_50;               //  50 MHz
    input   [9:0]   SW;
    input   [3:0]   KEY;
    output [17:0] LEDR;
    output [6:0] HEX0;
    // Declare your inputs and outputs here
    // Do not change the following outputs
    output          VGA_CLK;                //  VGA Clock
    output          VGA_HS;                 //  VGA H_SYNC
    output          VGA_VS;                 //  VGA V_SYNC
    output          VGA_BLANK_N;                //  VGA BLANK
    output          VGA_SYNC_N;             //  VGA SYNC
    output  [9:0]   VGA_R;                  //  VGA Red[9:0]
    output  [9:0]   VGA_G;                  //  VGA Green[9:0]
    output  [9:0]   VGA_B;                  //  VGA Blue[9:0]

    wire resetn;
    assign resetn = SW[9];

    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    wire [2:0] colour;
    wire [7:0] x;
    wire [6:0] y;
    wire writeEn;

    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
            .resetn(resetn),
            .clock(CLOCK_50),
            .colour(colour),
            .x(x),
            .y(y),
            .plot(writeEn),
            .VGA_R(VGA_R),
            .VGA_G(VGA_G),
            .VGA_B(VGA_B),
            .VGA_HS(VGA_HS),
            .VGA_VS(VGA_VS),
            .VGA_BLANK(VGA_BLANK_N),
            .VGA_SYNC(VGA_SYNC_N),
            .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
        defparam VGA.BACKGROUND_IMAGE = "black.mif";

    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.

    assign go = ~KEY[0];
    assign left = ~KEY[3];
    assign right = ~KEY[2];
    assign fire = ~KEY[1];
    wire [2:0] level, current_level;
    assign level = SW[2:0];

    wire load_level, level_pause, play, game_over, level_select; // game states
    wire [2:0] ani_state;
    wire player_move, bullet_move, animate_done;
    wire [3:0] enemy_count, enemy_out;
    wire [14:0] enemies;
    wire [7:0] playerX, bulletX, enemy0X, enemy1X, enemy2X, enemy3X, enemy4X, enemy5X, enemy6X, 
        enemy7X, enemy8X, enemy9X;
    wire [6:0] playerY, bulletY, enemy0Y, enemy1Y, enemy2Y, enemy3Y, enemy4Y, enemy5Y, enemy6Y,
        enemy7Y, enemy8Y, enemy9Y;
    wire [3:0] enemy0_width, enemy1_width, enemy2_width, enemy3_width, enemy4_width, enemy5_width,
        enemy6_width, enemy7_width, enemy8_width, enemy9_width;
    wire [2:0] enemy0_color, enemy1_color, enemy2_color, enemy3_color, enemy4_color, enemy5_color,
        enemy6_color, enemy7_color, enemy8_color, enemy9_color;
    wire enemy0_move, enemy1_move, enemy2_move, enemy3_move, enemy4_move, enemy5_move, enemy6_move,
        enemy7_move, enemy8_move, enemy9_move;
    wire player_hit0, player_hit1, player_hit2, player_hit3, player_hit4, player_hit5, player_hit6,
        player_hit7, player_hit8, player_hit9;
    wire bullet_hit0, bullet_hit1, bullet_hit2, bullet_hit3, bullet_hit4, bullet_hit5, bullet_hit6,
        bullet_hit7, bullet_hit8, bullet_hit9;
    wire enemy0_alive, enemy1_alive, enemy2_alive, enemy3_alive, enemy4_alive, enemy5_alive,
        enemy6_alive, enemy7_alive, enemy8_alive, enemy9_alive;
    reg [7:0] enemyX;
    reg [6:0] enemyY;
    reg [3:0] enemy_width;
    reg [2:0] enemy_color;

    assign enemy_count = 4'd10; // total number of instantiated enemies
    assign enemy_move = enemy0_move || enemy1_move || enemy2_move || enemy3_move || enemy4_move 
        || enemy5_move || enemy6_move || enemy7_move || enemy8_move || enemy9_move;
    assign player_hit = player_hit0 || player_hit1 || player_hit2 || player_hit3 || player_hit4 
        || player_hit5 || player_hit6 || player_hit7 || player_hit8 || player_hit9;
    assign bullet_hit = bullet_hit0 || bullet_hit1 || bullet_hit2 || bullet_hit3 || bullet_hit4 
        || bullet_hit5 || bullet_hit6 || bullet_hit7 || bullet_hit8 || bullet_hit9;
    assign enemy_alive = enemy0_alive || enemy1_alive || enemy2_alive || enemy3_alive || enemy4_alive
        || enemy5_alive || enemy6_alive || enemy7_alive || enemy8_alive || enemy9_alive;
    assign enemy0_enable = (enemies & 15'b000000000000001) > 0 ? 1 : 0;
    assign enemy1_enable = (enemies & 15'b000000000000010) > 0 ? 1 : 0;
    assign enemy2_enable = (enemies & 15'b000000000000100) > 0 ? 1 : 0;
    assign enemy3_enable = (enemies & 15'b000000000001000) > 0 ? 1 : 0;
    assign enemy4_enable = (enemies & 15'b000000000010000) > 0 ? 1 : 0;
    assign enemy5_enable = (enemies & 15'b000000000100000) > 0 ? 1 : 0;
    assign enemy6_enable = (enemies & 15'b000000001000000) > 0 ? 1 : 0;
    assign enemy7_enable = (enemies & 15'b000000010000000) > 0 ? 1 : 0;
    assign enemy8_enable = (enemies & 15'b000000100000000) > 0 ? 1 : 0;
    assign enemy9_enable = (enemies & 15'b000001000000000) > 0 ? 1 : 0;
    assign enemy0_color = 3'b001;
    assign enemy1_color = 3'b010;
    assign enemy2_color = 3'b011;
    assign enemy3_color = 3'b100;
    assign enemy4_color = 3'b101;
    assign enemy5_color = 3'b001;
    assign enemy6_color = 3'b010;
    assign enemy7_color = 3'b011;
    assign enemy8_color = 3'b100;
    assign enemy9_color = 3'b101;

    always@(*) begin
        case(enemy_out)
            4'd0: begin
                enemyX <= enemy0X;
                enemyY <= enemy0Y;
                enemy_width <= enemy0_width;
                enemy_color <= enemy0_color;
            end
            4'd1: begin
                enemyX <= enemy1X;
                enemyY <= enemy1Y;
                enemy_width <= enemy1_width;
                enemy_color <= enemy1_color;
            end
            4'd2: begin
                enemyX <= enemy2X;
                enemyY <= enemy2Y;
                enemy_width <= enemy2_width;
                enemy_color <= enemy2_color;
            end
            4'd3: begin
                enemyX <= enemy3X;
                enemyY <= enemy3Y;
                enemy_width <= enemy3_width;
                enemy_color <= enemy3_color;
            end
            4'd4: begin
                enemyX <= enemy4X;
                enemyY <= enemy4Y;
                enemy_width <= enemy4_width;
                enemy_color <= enemy4_color;
            end
            4'd5: begin
                enemyX <= enemy5X;
                enemyY <= enemy5Y;
                enemy_width <= enemy5_width;
                enemy_color <= enemy5_color;
            end
            4'd6: begin
                enemyX <= enemy6X;
                enemyY <= enemy6Y;
                enemy_width <= enemy6_width;
                enemy_color <= enemy6_color;
            end
            4'd7: begin
                enemyX <= enemy7X;
                enemyY <= enemy7Y;
                enemy_width <= enemy7_width;
                enemy_color <= enemy7_color;
            end
            4'd8: begin
                enemyX <= enemy8X;
                enemyY <= enemy8Y;
                enemy_width <= enemy8_width;
                enemy_color <= enemy8_color;
            end
            4'd9: begin
                enemyX <= enemy9X;
                enemyY <= enemy9Y;
                enemy_width <= enemy9_width;
                enemy_color <= enemy9_color;
            end
            default: begin
                enemyX <= enemy0X;
                enemyY <= enemy0Y;
                enemy_width <= enemy0_width;
                enemy_color <= enemy0_color;
            end
        endcase
    end

    hex_display hd0(
        .IN(current_level),
        .OUT(HEX0)
    );
    
    datapath d0(
        .playerX(playerX),
        .playerY(playerY),
        .enemyX(enemyX),
        .enemyY(enemyY),
        .enemy_color(enemy_color),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enemy_width(enemy_width),
        .enemy_count(enemy_count),
        .ani_state(ani_state),
        .resetn(resetn),
        .clk(CLOCK_50),
        .ani_done(animate_done),
        .enemy_out(enemy_out),
        .x(x),
        .y(y),
        .colour(colour),
        .drawEn(writeEn)
    );

    control c0(
        .go(go),
        .player_hit(player_hit),
        .enemy_alive(enemy_alive),
        .resetn(resetn),
        .clk(CLOCK_50),
        .load_level(load_level),
        .level_pause(level_pause),
        .play(play),
        .game_over(game_over),
        .level_select(level_select)
    );

    player_control pc0(
        .left(left),
        .right(right),
        .play(play),
        .load_level(load_level),
        .resetn(resetn),
        .clk(CLOCK_50),
        .move(player_move),
        .playerX(playerX),
        .playerY(playerY)
    );
    
    bullet_control bc0(
        .fire(fire),
        .playerX(playerX),
        .playerY(playerY),
        .bullet_hit(bullet_hit),
        .play(play),
        .load_level(load_level),
        .resetn(resetn),
        .clk(CLOCK_50),
        .move(bullet_move),
        .bulletX(bulletX),
        .bulletY(bulletY)
    );

    animate_control ac0(
        .load_level(load_level),
        .game_over(game_over),
        .player_move(player_move),
        .bullet_move(bullet_move),
        .enemy_move(enemy_move),
        .ani_done(animate_done),
        .resetn(resetn),
        .clk(CLOCK_50),
        .ani_state(ani_state)
    );
    
    level_select ls0(
        .level(level),
        .level_select(level_select),
        .clk(CLOCK_50),
        .current_level(current_level),
        .enemies(enemies)
    );

    enemy_control ec0(
        .width(4'd13),
        .rate_div(28'd1000000),
        .start_x(8'd40),
        .start_y(7'd30),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b0),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy0_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit0),
        .bullet_hit(bullet_hit0),
        .move(enemy0_move),
        .enemyX(enemy0X),
        .enemyY(enemy0Y),
        .enemy_width(enemy0_width),
        .alive(enemy0_alive)
    );

    enemy_control ec1(
        .width(4'd13),
        .rate_div(28'd1000000),
        .start_x(8'd120),
        .start_y(7'd30),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b1),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy1_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit1),
        .bullet_hit(bullet_hit1),
        .move(enemy1_move),
        .enemyX(enemy1X),
        .enemyY(enemy1Y),
        .enemy_width(enemy1_width),
        .alive(enemy1_alive)
    );

    enemy_control ec2(
        .width(4'd9),
        .rate_div(28'd2000000),
        .start_x(8'd40),
        .start_y(7'd30),
        .d_x(3'd2),
        .d_y(3'd3),
        .leftwards(1'b0),
        .upwards(1'b1),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy2_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit2),
        .bullet_hit(bullet_hit2),
        .move(enemy2_move),
        .enemyX(enemy2X),
        .enemyY(enemy2Y),
        .enemy_width(enemy2_width),
        .alive(enemy2_alive)
    );
    
    enemy_control ec3(
        .width(4'd9),
        .rate_div(28'd2000000),
        .start_x(8'd120),
        .start_y(7'd30),
        .d_x(3'd2),
        .d_y(3'd3),
        .leftwards(1'b1),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy3_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit3),
        .bullet_hit(bullet_hit3),
        .move(enemy3_move),
        .enemyX(enemy3X),
        .enemyY(enemy3Y),
        .enemy_width(enemy3_width),
        .alive(enemy3_alive)
    );
     
    enemy_control ec4(
        .width(4'd9),
        .rate_div(28'd1000000),
        .start_x(8'd80),
        .start_y(7'd30),
        .d_x(3'd2),
        .d_y(3'd1),
        .leftwards(1'b0),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy4_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit4),
        .bullet_hit(bullet_hit4),
        .move(enemy4_move),
        .enemyX(enemy4X),
        .enemyY(enemy4Y),
        .enemy_width(enemy4_width),
        .alive(enemy4_alive)
    );
    
    enemy_control ec5(
        .width(4'd6),
        .rate_div(28'd500000),
        .start_x(8'd50),
        .start_y(7'd30),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b0),
        .upwards(1'b1),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy5_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit5),
        .bullet_hit(bullet_hit5),
        .move(enemy5_move),
        .enemyX(enemy5X),
        .enemyY(enemy5Y),
        .enemy_width(enemy5_width),
        .alive(enemy5_alive)
    );
    
    enemy_control ec6(
        .width(4'd6),
        .rate_div(28'd700000),
        .start_x(8'd110),
        .start_y(7'd30),
        .d_x(3'd1),
        .d_y(3'd2),
        .leftwards(1'b1),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy6_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit6),
        .bullet_hit(bullet_hit6),
        .move(enemy6_move),
        .enemyX(enemy6X),
        .enemyY(enemy6Y),
        .enemy_width(enemy6_width),
        .alive(enemy6_alive)
    );
    
    enemy_control ec7(
        .width(4'd6),
        .rate_div(28'd1500000),
        .start_x(8'd80),
        .start_y(7'd70),
        .d_x(3'd2),
        .d_y(3'd3),
        .leftwards(1'b0),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy7_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit7),
        .bullet_hit(bullet_hit7),
        .move(enemy7_move),
        .enemyX(enemy7X),
        .enemyY(enemy7Y),
        .enemy_width(enemy7_width),
        .alive(enemy7_alive)
    );
    
    enemy_control ec8(
        .width(4'd3),
        .rate_div(28'd1000000),
        .start_x(8'd20),
        .start_y(7'd70),
        .d_x(3'd3),
        .d_y(3'd2),
        .leftwards(1'b1),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy8_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit8),
        .bullet_hit(bullet_hit8),
        .move(enemy8_move),
        .enemyX(enemy8X),
        .enemyY(enemy8Y),
        .enemy_width(enemy8_width),
        .alive(enemy8_alive)
    );
    
    enemy_control ec9(
        .width(4'd3),
        .rate_div(28'd300000),
        .start_x(8'd140),
        .start_y(7'd70),
        .d_x(3'd1),
        .d_y(3'd1),
        .leftwards(1'b1),
        .upwards(1'b0),
        .playerX(playerX),
        .playerY(playerY),
        .bulletX(bulletX),
        .bulletY(bulletY),
        .enable(enemy9_enable),
        .load_level(load_level),
        .play(play),
        .resetn(resetn),
        .clk(CLOCK_50),
        .player_hit(player_hit9),
        .bullet_hit(bullet_hit9),
        .move(enemy9_move),
        .enemyX(enemy9X),
        .enemyY(enemy9Y),
        .enemy_width(enemy9_width),
        .alive(enemy9_alive)
    );
endmodule

// controls game states
module control(
    input go,
    input player_hit,
    input enemy_alive,
    input resetn,
    input clk,
    output load_level,
    output level_pause,
    output play,
    output game_over,
    output level_select
    );

    reg [2:0] state, state_next;
    localparam LEVEL_SELECT = 3'b000, LOAD_LEVEL = 3'b001, LEVEL_PAUSE = 3'b010,    // states
            PLAY_START = 3'b011, PLAY = 3'b100, GAME_OVER = 3'b101, PAUSING = 3'b110;

    always@(*)
    begin: state_table
        case (state)
            LEVEL_SELECT: begin
                    if (go) state_next <= LOAD_LEVEL;
                    else state_next <= LEVEL_SELECT;
            end
            LOAD_LEVEL: begin
                    if (!go) state_next <= LEVEL_PAUSE;
                    else state_next <= LOAD_LEVEL;
            end
            LEVEL_PAUSE: begin
                if (go) state_next <= PLAY_START;
                else state_next <= LEVEL_PAUSE;
            end
            PLAY_START: begin
                if (!go) state_next <= PLAY;
                else state_next <= PLAY_START;
            end
            PLAY: begin
                if (go) state_next <= PAUSING;
                else if (player_hit || !enemy_alive) state_next <= GAME_OVER;
                else state_next <= PLAY;
            end
            PAUSING: begin
                if (!go) state_next <= LEVEL_PAUSE;
                else state_next <= PAUSING;
            end
            GAME_OVER: begin
                if (go) state_next <= LOAD_LEVEL;
                else state_next <= GAME_OVER;
            end
            default: state_next = LEVEL_SELECT;
        endcase
    end // state_table

    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(!resetn)
            state <= LEVEL_SELECT;
        else
            state <= state_next;
    end // state_FFS

    // Output logic
    assign load_level = (state == LOAD_LEVEL);
    assign level_pause = (state == LEVEL_PAUSE);
    assign play = (state == PLAY);
    assign game_over = (state == GAME_OVER);
    assign level_select = (state == LEVEL_SELECT);
endmodule

// controls what is being drawn
module animate_control(
    input load_level,
    input game_over,
    input player_move,
    input bullet_move,
    input enemy_move,
    input ani_done,
    input resetn,
    input clk,
    output reg [2:0] ani_state
    );

    reg [2:0] state_next;
    localparam IDLE = 3'b000, DRAW = 3'b001, LEVEL = 3'b010, ERASE = 3'b011,    // draw states
            ERASEtoDRAW = 3'b100, OVER_ERASE = 3'b101, GAME_OVER = 3'b110, OVERtoLEVEL = 3'b111;

    always@(*)
    begin: state_table
        case (ani_state)
            IDLE: begin
                if (game_over) state_next <= GAME_OVER;
                else if (player_move || enemy_move || bullet_move) state_next <= ERASE;
                else if (load_level) state_next <= LEVEL;
                else state_next <= IDLE;
            end
            DRAW: begin
                if (ani_done) state_next <= IDLE;
                else state_next <= DRAW;
            end
            ERASE: begin
                if (ani_done) state_next <= ERASEtoDRAW;
                else state_next <= ERASE;
            end
            LEVEL: begin
                if (ani_done) state_next <= IDLE;
                else state_next <= LEVEL;
            end
            ERASEtoDRAW: begin
                if (!ani_done) state_next <= DRAW;
                else state_next <= ERASEtoDRAW;
            end
            GAME_OVER: begin
                if (load_level) state_next <= OVER_ERASE;
                else state_next <= GAME_OVER;
            end
            OVER_ERASE: begin
                if (ani_done) state_next <= OVERtoLEVEL;
                else state_next <= OVER_ERASE;
            end
            OVERtoLEVEL: begin
                if (!ani_done) state_next <= LEVEL;
                else state_next <= OVERtoLEVEL;
            end
            default: state_next = IDLE;
        endcase
    end // state_table

    // State Registers
    always @(posedge clk)
    begin: state_FFs
        if(!resetn)
            ani_state <= IDLE;
        else
            ani_state <= state_next;
    end // state_FFS
endmodule

module level_select(
    input [2:0] level,
    input level_select,
    input clk,
    output reg [2:0] current_level,
    output reg [14:0] enemies
    );
    
    always@(posedge clk) begin
        if (level_select) begin
            case (level)
                3'd1: begin
                    enemies <= 15'b000000000000011;  
                end
                3'd2: begin
                    enemies <= 15'b000000000001100;
                end
                3'd3: begin
                    enemies <= 15'b000000000010011;
                end
                3'd4: begin
                    enemies <= 15'b000000000011100;
                end
                3'd5: begin
                    enemies <= 15'b000000011100000;
                end
                3'd6: begin
                    enemies <= 15'b000001110000000;
                end
                3'd7: begin
                    enemies <= 15'b000001111100000;
                end
                default: begin
                    enemies <= 15'b000000000000011;
                end
            endcase
            current_level <= level;
        end
    end
endmodule

// does the drawing
module datapath(
    input [7:0] playerX,
    input [6:0] playerY,
    input [7:0] enemyX,
    input [6:0] enemyY,
    input [2:0] enemy_color,
    input [7:0] bulletX,
    input [6:0] bulletY,
    input [3:0] enemy_width,
    input [3:0] enemy_count,
    input [2:0] ani_state,
    input resetn,
    input clk,
    output reg ani_done,
    output reg [3:0] enemy_out,
    output reg [7:0] x,
    output reg [6:0] y,
    output reg [2:0] colour,
    output reg drawEn
    );

    localparam IDLE = 3'b000, DRAW = 3'b001, LEVEL = 3'b010, ERASE = 3'b011,    // draw states
            ERASEtoDRAW = 3'b100, OVER_ERASE = 3'b101, GAME_OVER = 3'b110, OVERtoLEVEL = 3'b111;
    reg [27:0] counter;
    reg [7:0] player_x, enemy_x, bullet_x;
    reg [6:0] player_y, enemy_y, bullet_y;
    reg bullet_drawn;

    initial begin
        ani_done <= 0;
        counter <= 0;
        enemy_out <= 0;
        bullet_drawn <= 0;
    end

    always@(posedge clk) begin
        if (!resetn || ani_state == ERASE || ani_state == OVER_ERASE) begin
            drawEn <= 1;
            colour <= 3'b000;
            if (counter == 0) begin
                x <= 0;
                y <= 0;
            end else if (counter < `SCREEN_W * `SCREEN_H) begin
                if (y <= `SCREEN_H) begin
                    if (x < `SCREEN_W) begin
                        x <= x + 1;
                    end else if (y < `SCREEN_H) begin
                        x <= 0;
                        y <= y + 1;
                    end
                end
            end
            counter <= counter + 1;

            // done drawing
            if (counter > `SCREEN_W * `SCREEN_H) begin
                ani_done <= 1'b1;
                drawEn <= 0;
            end
        end else if (ani_state == LEVEL || ani_state == DRAW) begin
            drawEn <= 1;
            colour <= `PLAYER_COLOR; // default
            if (counter == 0) begin
                player_x <= playerX;
                player_y <= playerY;
                bullet_x <= bulletX;
                bullet_y <= bulletY;
                x <= playerX;
                y <= playerY;
                bullet_drawn <= 0;
            end else if (counter < `PLAYER_SIZE) begin
                // draw player
                if (y <= player_y + `PLAYER_WIDTH - 1) begin
                    if (x < player_x + `PLAYER_WIDTH - 1) begin
                        x <= x + 1;
                    end else if (y < player_y + `PLAYER_WIDTH - 1) begin
                        x <= player_x;
                        y <= y + 1;
                    end
                end
            end else if (counter < `PLAYER_SIZE + (enemy_width * enemy_width)) begin
                // draw enemies
                if (counter == `PLAYER_SIZE) begin
                    colour <= enemy_color;
                    x <= enemyX;
                    y <= enemyY;
                    enemy_x <= enemyX;
                    enemy_y <= enemyY;
                end else if (y <= enemy_y + enemy_width - 1 && !bullet_drawn) begin
                    colour <= enemy_color;
                    if (x < enemy_x + enemy_width - 1) begin
                        x <= x + 1;
                    end else if (y < enemy_y + enemy_width - 1) begin
                        x <= enemy_x;
                        y <= y + 1;
                    end
                end
            end else if (counter < `PLAYER_SIZE + (enemy_width * enemy_width) + 1) begin
                // draw phallus
                x <= player_x + 1;
                y <= player_y - 1;
            end else if (counter < `PLAYER_SIZE + (enemy_width * enemy_width) + 2) begin
                // draw bullet
                x <= bullet_x;
                y <= bullet_y;
                bullet_drawn <= 1;
            end
            
            if ((counter == `PLAYER_SIZE + (enemy_width * enemy_width) - 1
                || (counter >= `PLAYER_SIZE + (enemy_width * enemy_width) && enemy_width == 0))
                && enemy_out < enemy_count - 1) begin
                // draw next enemy
                enemy_out <= enemy_out + 1;
                counter <= `PLAYER_SIZE;
            end else begin
                counter <= counter + 1;
            end

            // done drawing
            if (counter >= `PLAYER_SIZE + (enemy_width * enemy_width) + 1) begin
                ani_done <= 1'b1;
                enemy_out <= 0;
            end
        end else begin
            drawEn <= 0;
            ani_done <= 0;
            counter <= 0;
        end
    end
endmodule

module hex_display(IN, OUT);
    input [3:0] IN;
    output reg [6:0] OUT;
     
    always @(*)
    begin
        case(IN[3:0])
            4'b0000: OUT = 7'b1000000;
            4'b0001: OUT = 7'b1111001;
            4'b0010: OUT = 7'b0100100;
            4'b0011: OUT = 7'b0110000;
            4'b0100: OUT = 7'b0011001;
            4'b0101: OUT = 7'b0010010;
            4'b0110: OUT = 7'b0000010;
            4'b0111: OUT = 7'b1111000;
            4'b1000: OUT = 7'b0000000;
            4'b1001: OUT = 7'b0011000;
            4'b1010: OUT = 7'b0001000;
            4'b1011: OUT = 7'b0000011;
            4'b1100: OUT = 7'b1000110;
            4'b1101: OUT = 7'b0100001;
            4'b1110: OUT = 7'b0000110;
            4'b1111: OUT = 7'b0001110;
            
            default: OUT = 7'b0111111;
        endcase
    end
endmodule
