namespace Quantum.QSharpApplication1 {

    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;

    operation Check_error_rate (array1:Int[], array2:Int[]) : Int{

        mutable error_times = 0;
        mutable total_times = Length(array1);

        for (i in 0..(total_times - 1)) {
            if (array1[i] != array2[i]){
                set error_times += 1;
			}
        }

        let error_rate = (error_times * 100) / total_times;
        return error_rate ;
    }


    operation Binary_array_to_Int (array:Int[]) : Int{

        mutable value = 0;

        for (i in 0..(Length(array) - 1)) {
            set value += (2^i) * array[Length(array) - 1 - i];
        }

        return value;
    }


    operation Preshared_Universal_Hash (SK:Int[] , K2:Int[]) : Int[] {

        let SK_part1 = SK[...Length(SK)/2];
        let SK_part2 = SK[Length(SK)/2+1...];

        let K2_part1 = K2[...Length(K2)/2];
        let K2_part2 = K2[Length(K2)/2+1...];

        mutable hash_value = ( Binary_array_to_Int(SK_part1) * Binary_array_to_Int(K2_part1) * 99 + Binary_array_to_Int(SK_part2) * Binary_array_to_Int(K2_part2) * 9 ) % (2^Length(K2));

        mutable hash_value_binary = new Int[Length(K2)];

        for (i in 0..(Length(K2) - 1)) {

            if (hash_value == 0){
                set hash_value_binary w/= (Length(K2)-1-i) <- 0;
			}
            elif (hash_value == 1){
                set hash_value_binary w/= (Length(K2)-1-i) <- 1;
                set hash_value = 0;
            }
            else{
                set hash_value_binary w/= (Length(K2)-1-i) <- hash_value % 2;
                set hash_value = hash_value/2;
			}
        }

        return hash_value_binary;
    }


    operation MeasureResendProtocol (n:Int, m:Int, Eve_all_Z:Bool, Eve_ZX:Bool) : Unit {

        Message($"n: {n} , m: {m}");

        // Step0: Alice and Bob preshare two keys K1, K2, and Hash function based on K2

        mutable K1 = new Int[n+m];
        mutable K2 = new Int[m];

        for (i in 0..(n+m - 1)) {
            set K1 w/= i <- RandomInt(2);
        }
        for (i in 0..(m - 1)) {
            set K2 w/= i <- RandomInt(2);
        }

        Message($"preshare key K1 : {K1}");
        Message($"preshare key K2 : {K2}");

        // Step1: Alice prepares SK||Hash(SK) --> SA
        Message("");
        Message("Step1");

        mutable SK = new Int[n];
        for (i in 0..(n - 1)) {
            set SK w/= i <- RandomInt(2);
        }
        Message($"session key SK : {SK}");

        let HashSK = Preshared_Universal_Hash(SK, K2);
        Message($"hash value of session key SK : {HashSK}");

        let SA = SK + HashSK ;
        Message($"SA : {SA}");

        // Step2: Alice inserts random SD into SA based on K1
        //        SA: |0> (0) or |1> (1)     SD: |0> |+> (0) or |1> |-> (1)   ==> QA
        Message("");
        Message("Step2");

        mutable SD = new Int[n+m];
        mutable SD_basis = new Int[n+m];

        for (i in 0..(n+m - 1)) {
            set SD w/= i <- RandomInt(2);
        }
        for (i in 0..(n+m - 1)) {
            set SD_basis w/= i <- RandomInt(2);
        }

        mutable string1_step2 = "";
        mutable string2_step2 = "";

        using (qubits = Qubit[2*(n+m)]) {

            for (i in 0..(n+m - 1)) {
                if (K1[i] == 0){ // SD SA
                    set string1_step2 += "SD  SA  " ;

				    if (SD[i] == 0 and SD_basis[i] == 0){
                        set string2_step2 += "|0> " ;
                    }
                    elif (SD[i] == 1 and SD_basis[i] == 0){
                        set string2_step2 += "|1> " ;
                        X(qubits[2*i]);
                    }
                    elif (SD[i] == 0 and SD_basis[i] == 1){
                        set string2_step2 += "|+> " ;
                        H(qubits[2*i]);
                    }
                    elif (SD[i] == 1 and SD_basis[i] == 1){
                        set string2_step2 += "|-> " ;
                        X(qubits[2*i]);
                        H(qubits[2*i]);
                    }

                    if (SA[i] == 0){
                        set string2_step2 += "|0> " ;
					}
                    elif (SA[i] == 1){
                        set string2_step2 += "|1> " ;
                        X(qubits[2*i+1]);
					}
				}
                else{ // SA SD
                    set string1_step2 += "SA  SD  " ;

                    if (SA[i] == 0){
                        set string2_step2 += "|0> " ;
					}
                    elif (SA[i] == 1){
                        set string2_step2 += "|1> " ;
                        X(qubits[2*i]);
					}
                
                    if (SD[i] == 0 and SD_basis[i] == 0){
                        set string2_step2 += "|0> " ;
                    }
                    elif (SD[i] == 1 and SD_basis[i] == 0){
                        set string2_step2 += "|1> " ;
                        X(qubits[2*i+1]);
                    }
                    elif (SD[i] == 0 and SD_basis[i] == 1){
                        set string2_step2 += "|+> " ;
                        H(qubits[2*i+1]);
                    }
                    elif (SD[i] == 1 and SD_basis[i] == 1){
                        set string2_step2 += "|-> " ;
                        X(qubits[2*i+1]);
                        H(qubits[2*i+1]);
                    }
				}
            }

            Message(string1_step2);
            Message(string2_step2);
            Message("Alice sends QA to Bob");


            // There may be an eavesdropper, Eve.
            if (Eve_all_Z == false and Eve_ZX == false){
                // nothing
			}
            elif (Eve_all_Z == true and Eve_ZX == false){
                Message("");
                Message("Eve's attack (all Z-basis measurements)");

                for (i in 0..(2*(n+m) - 1)) {
                    if (M(qubits[i]) == Zero){
                        Reset(qubits[i]);
                    }
                    else{
                        Reset(qubits[i]);
                        X(qubits[i]);
					}
                }
            }
            elif (Eve_all_Z == false and Eve_ZX == true){
                Message("");
                Message("Eve's attack (Z-basis and X-basis measurements)");

                mutable Eve_basis = new Int[2*(n+m)];
                for (i in 0..(2*(n+m) - 1)) {
                    set Eve_basis w/= i <- RandomInt(2);
                }

                for (i in 0..(2*(n+m) - 1)) {
                    if(Eve_basis[i] == 0){
                        if (M(qubits[i]) == Zero){
                            Reset(qubits[i]);
                        }
                        else{
                            Reset(qubits[i]);
                            X(qubits[i]);
					    }
					}
                    else{
                        H(qubits[i]);

                        if (M(qubits[i]) == Zero){
                            Reset(qubits[i]);
                            H(qubits[i]);
                        }
                        else{
                            Reset(qubits[i]);
                            X(qubits[i]);
                            H(qubits[i]);
					    }
					}
                }
            }
            else{
                fail $"It's unacceptable that both Eve_all_Z and Eve_ZX are true.";
			}


            // Step3 : for each qubit of QA Bob receives
            //         SA -> Z measure, resend |0> or |1> the same as measurement result
            //         SD -> reflect (no any operation or measurement)
            Message("");
            Message("Step3");

            mutable Bob_measurement_result = new Int[n+m];

            mutable string1_step3 = "";

            for (i in 0..(n+m - 1)) {
                if (K1[i] == 0){ // SD SA
				    if (M(qubits[2*i+1]) == Zero){
                        set Bob_measurement_result w/= i <- 0;
                        set string1_step3 += "    0   ";
                        Reset(qubits[2*i+1]);
                    }
                    else{
                        set Bob_measurement_result w/= i <- 1;
                        set string1_step3 += "    1   ";
                        Reset(qubits[2*i+1]);
                        X(qubits[2*i+1]);
					}
				}
                else{ // SA SD
                    if (M(qubits[2*i]) == Zero){
                        set Bob_measurement_result w/= i <- 0;
                        set string1_step3 += "0       ";
                        Reset(qubits[2*i]);
                    }
                    else{
                        set Bob_measurement_result w/= i <- 1;
                        set string1_step3 += "1       ";
                        Reset(qubits[2*i]);
                        X(qubits[2*i]);
					}
				}
            }

            Message("Bob's measurement result :");
            Message(string1_step3);
            Message("Bob sends QA' to Alice");

            // Step4 : Alice receives QA'. Z measure SA', Z or X measure SD', and check.
            //         Bob checks Hash(SK') == Hash(SK)'.
            Message("");
            Message("Step4");

            mutable Alice_SA_measurement_result = new Int[n+m];
            mutable Alice_SD_measurement_result = new Int[n+m];

            mutable string1_step4_SA = "";
            mutable string2_step4_SD = "";

            for (i in 0..(n+m - 1)) {
                if (K1[i] == 0){ // SD SA
				    if(SD_basis[i] == 1){
                        H(qubits[2*i]);
                    }
                    if (M(qubits[2*i]) == Zero){
                        set Alice_SD_measurement_result w/= i <- 0;
                        set string2_step4_SD += "0   ";
                    }
                    else{
                        set Alice_SD_measurement_result w/= i <- 1;
                        set string2_step4_SD += "1   ";
					}

                    if (M(qubits[2*i+1]) == Zero){
                        set Alice_SA_measurement_result w/= i <- 0;
                        set string1_step4_SA += "0   ";
                    }
                    else{
                        set Alice_SA_measurement_result w/= i <- 1;
                        set string1_step4_SA += "1   ";
					}
				}
                else{ // SA SD
                    if (M(qubits[2*i]) == Zero){
                        set Alice_SA_measurement_result w/= i <- 0;
                        set string1_step4_SA += "0   ";
                    }
                    else{
                        set Alice_SA_measurement_result w/= i <- 1;
                        set string1_step4_SA += "1   ";
					}

                    if(SD_basis[i] == 1){
                        H(qubits[2*i+1]);
                    }
                    if (M(qubits[2*i+1]) == Zero){
                        set Alice_SD_measurement_result w/= i <- 0;
                        set string2_step4_SD += "0   ";
                    }
                    else{
                        set Alice_SD_measurement_result w/= i <- 1;
                        set string2_step4_SD += "1   ";
					}
				}
            }

            Message("Alice's measurement result :");
            Message($"SA' : {string1_step4_SA}");  
            Message($"SD' : {string2_step4_SD}");

            let Alice_SA_error_rate = Check_error_rate(Alice_SA_measurement_result, SA);
            let Alice_SD_error_rate = Check_error_rate(Alice_SD_measurement_result, SD);

            Message($"Alice_SA'_error_rate : {Alice_SA_error_rate} %");
            Message($"Alice_SD'_error_rate : {Alice_SD_error_rate} %");

            // Bob's check'
            Message("");
            Message("Bob");

            let Bob_SK = Bob_measurement_result[...n-1];
            let Bob_HashSK = Bob_measurement_result[n...];
            Message($"Bob_SK' : {Bob_SK}");
            Message($"Bob_HashSK' : {Bob_HashSK}");

            let Hash_value_of_Bob_SK = Preshared_Universal_Hash(Bob_SK, K2);

            let Bob_HashSK_error_rate = Check_error_rate(Bob_HashSK, Hash_value_of_Bob_SK);
            Message($"Bob_HashSK'_error_rate : {Bob_HashSK_error_rate} %");

            ResetAll(qubits);
		}

    }
}
