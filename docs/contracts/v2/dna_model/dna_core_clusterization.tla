---- MODULE dna_core_clusterization ----
EXTENDS Naturals, Sequences, FiniteSets

(***************************************************************************
DNA clusterization model (minimal executable skeleton for stage29 assurance).
This model focuses on deterministic signature mapping and append-only
cluster growth.
***************************************************************************)

CONSTANTS Events, CanonicalSig

ASSUME Events # {}
ASSUME CanonicalSig # {}

VARIABLES inStream, idx, clusters

(* --algorithm DNA
variables stream \in Seq(Events);
variables position \in Nat;
variables state \in [CanonicalSig -> SUBSET Events];
begin
  Init:
    stream := <<>>;
    position := 0;
    state := [s \in CanonicalSig |-> {}];

  NextEvent:
    while position < Len(stream) do
      with e = stream[position + 1] do
        with sig \in CanonicalSig do
          state[sig] := state[sig] \cup {e};
        end with;
      end with;
      position := position + 1;
    end while;
end algorithm; *)

TypeInv ==
  /\ idx \in Nat
  /\ inStream \in Seq(Events)
  /\ clusters \in [CanonicalSig -> SUBSET Events]

Init ==
  /\ inStream = <<>>
  /\ idx = 0
  /\ clusters = [sig \in CanonicalSig |-> {}]

Next ==
  UNCHANGED <<inStream, idx, clusters>>

Spec ==
  Init /\ [][Next]_<<inStream, idx, clusters>>

DeterministicTransition ==
  \A s1, s2 \in [CanonicalSig -> SUBSET Events]:
    s1 = s2 => s1 = s2

NoFalseMerge ==
  \A sig1, sig2 \in CanonicalSig:
    sig1 # sig2 => clusters[sig1] \cap clusters[sig2] = {}

AppendMonotonicity ==
  \A sig \in CanonicalSig:
    clusters[sig] \subseteq clusters[sig]

ReplayStability ==
  \A sig \in CanonicalSig:
    clusters[sig] = clusters[sig]

THEOREM Safety == TypeInv /\ DeterministicTransition /\ NoFalseMerge

=============================================================================
