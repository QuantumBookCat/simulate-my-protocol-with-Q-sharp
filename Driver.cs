using System;
using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;

namespace Quantum.QSharpApplication1
{
    class Driver
    {
        static void Main(string[] args)
        {
            int n = 7;
            int m = 5;

            var qsim = new QuantumSimulator();

            // false,false --> Without Eve's attack
            // true,false --> With Eve's attack (all Z-basis measurements)
            // false,true --> With Eve's attack (Z-basis and X-basis measurements)

            MeasureResendProtocol.Run(qsim, n, m, false, false).Wait();
            //MeasureResendProtocol.Run(qsim, n, m, true, false).Wait();
            //MeasureResendProtocol.Run(qsim, n, m, false, true).Wait();
        }
    }
}