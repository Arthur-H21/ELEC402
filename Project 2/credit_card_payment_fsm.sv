/* ELEC 402 Project 1 - System Verilog FSM Project 
 * Name: Arthur Hsueh
 * ID: 21582168
 * Description: This fsm is a generalized credit card
 *              payment controller, capable of taking payments
 *              in visa, mastercard and amex.
*/

module credit_card_payment_fsm
(
    input clk, reset,
    input process_init,
    input visa_choice_in,
    input mastercard_choice_in,
    input amex_choice_in,
    input pymt_amt_conf,
    input pymt_amt_denied,
    input pin_fail,
    input pin_success,
    input transaction_fail,
    input transaction_success,
    output logic light_bit,
    output logic [1:0] card_choice,
    output logic pymt_amt_print,
    output logic pin_process_init,
    output logic pymt_process_init,
    output logic process_abort
);

// wire delclarations
logic [1:0] fail_counter;   // fail counter, used for pin fail detection
logic [3:0] state, nextstate;           // state wire, will hold the value of all localparams

// state parameter definition
// This glitch-free method was taught by Dr. Yair Linn, in
// CPEN 311.
                                //   12'b1098_6543210
parameter idle                     = 4'b0000;   // idle state wait for process_init
parameter init_process             = 4'b0001;   // starts the process 
parameter wait_credit_choice       = 4'b0010;   // waits for the user input of their credit card payment choice
parameter choice_visa              = 4'b0011;   // user has chosen visa, output bits will be driven
parameter choice_mastercard        = 4'b0100;   // user has chosen mastercard, output bits will be driven
parameter choice_amex              = 4'b0101;   // use has chosen amex, output bits will be driven
parameter init_amount_confirm      = 4'b0110;   // initates the confirmation of the amount to be paid
parameter wait_amount_confirm      = 4'b0111;   // wait fro the use to confirm the payment amount
parameter init_pin_process         = 4'b1000;   // initates the input of the user's pin
parameter wait_pin_process         = 4'b1001;   // waits for user to input their pin
parameter init_payment_handle      = 4'b1010;   // initates the credit card payment handling
parameter wait_payment_handle      = 4'b1011;   // waits for credit card to be confirmed 
parameter payment_success          = 4'b1100;   // payment has been success fully processed
parameter payment_fail             = 4'b1101;   // payment has failed and the process will be aborted.

// State register
always_ff@(posedge clk)
begin
    if (reset)          state <= idle;
    else                state <= nextstate;
end

// Next State Logic
always_comb
    case(state)
        idle:                   if (process_init) nextstate = init_process;
                                else nextstate = idle;
        init_process:           nextstate = wait_credit_choice;
        wait_credit_choice:     if (visa_choice_in) nextstate = choice_visa;
                                else if (mastercard_choice_in) nextstate = choice_mastercard;
                                else if (amex_choice_in) nextstate = choice_amex;
                                else nextstate = wait_credit_choice;   
        choice_visa:            nextstate = init_amount_confirm;
        choice_mastercard:      nextstate = init_amount_confirm;
        choice_amex:            nextstate = init_amount_confirm;
        init_amount_confirm:    nextstate = wait_amount_confirm;
        wait_amount_confirm:    if (pymt_amt_conf) nextstate = init_pin_process;
                                else if (pymt_amt_denied) nextstate = payment_fail;
                                else nextstate = wait_amount_confirm;
        init_pin_process:       nextstate = wait_pin_process;
        wait_pin_process:       if (fail_counter == 2'b11) nextstate = payment_fail;
                                else if (pin_success) nextstate = init_payment_handle;
                                else if (pin_fail) begin
                                    nextstate = init_pin_process;
                                    fail_counter = fail_counter + 1'b1;
                                    end
                                else nextstate = wait_pin_process;
        init_payment_handle:    nextstate = wait_payment_handle;
        wait_payment_handle:    if (transaction_success) nextstate = payment_success;
                                else if (transaction_fail) nextstate = payment_fail;
                                else nextstate = wait_payment_handle;
        payment_success:        begin 
                                    nextstate = idle;
                                    fail_counter = 2'b00;
                                end
        payment_fail:           begin 
                                    nextstate = idle;
                                    fail_counter = 2'b00;
                                end
        default:                begin nextstate = idle; fail_counter = 2'b00; end
    endcase

// Output Logic
assign light_bit                    = (state != idle);     // A simple bit for a light, 0 when idle, 1 when process running
assign card_choice                  = (state == choice_visa) ? 2'b01 : ((state == choice_mastercard) ? 2'b10 : ((state == choice_amex) ? 2'b11 : 2'b00));   // 2 bits for 3 possible card choices, 00 otherwise
assign pymt_amt_print               = (state == init_amount_confirm);     // bit to trigger external printing of payment amount
assign pin_process_init             = (state == init_pin_process);     // bit to trigger external processing of pin entry/confirmation
assign pymt_process_init            = (state == init_payment_handle);     // bit to trigger external credit card payment handling
assign process_abort                = (state == payment_fail);     // bit to trigger an abort to all external processes of the paymet handling.

endmodule