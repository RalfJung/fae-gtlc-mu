From fae_gtlc_mu.refinements.static_gradual Require Export logical_relation resources_right compat_easy help_left.
From fae_gtlc_mu.cast_calculus Require Export types typing.
From fae_gtlc_mu.stlc_mu Require Export lang.
From fae_gtlc_mu.cast_calculus Require Export lang.
From iris.algebra Require Import list.
From iris.proofmode Require Import tactics.
From iris.program_logic Require Import lifting.
From fae_gtlc_mu.cast_calculus Require Export types.
From fae_gtlc_mu.cast_calculus Require Export consistency.structural.definition.
From fae_gtlc_mu.backtranslation Require Export cast_help.general cast_help.extract cast_help.embed.

(* Coercion stlc_mu.lang.of_val : stlc_mu.lang.val >-> stlc_mu.lang.expr. *)
(* Coercion cast_calculus.lang.of_val : cast_calculus.lang.val >-> cast_calculus.lang.expr. *)

(* Notation "# v" := (of_val v) (at level 20). *)

Section defs.
  Context `{!heapG Σ,!gradRN Σ}.
  Notation D := (prodO stlc_mu.lang.valO cast_calculus.lang.valO -n> iPropO Σ).
  (* Implicit Types e : stlc_mu.lang.expr. *)
  (* Implicit Types e : stlc_mu.lang.expr. *)
  Implicit Types fs : list stlc_mu.lang.val.
  (* Implicit Types f : stlc_mu.lang.val. *)
  Implicit Types A : list (cast_calculus.types.type * cast_calculus.types.type).
  (* Implicit Types a : (cast_calculus.types.type * cast_calculus.types.type). *)
  Local Hint Resolve to_of_val : core.

  (** We need to "close up" 𝓕 pC with functions... *)

  Definition 𝓕c {A} {τi τf} (pC : cons_struct A τi τf) fs : stlc_mu.lang.expr :=
    (𝓕 pC).[stlc_mu.typing.env_subst fs].

  (** 𝓕 pC is a value after substitution *)

  Lemma 𝓕c_is_value {A} {τi τf} (pC : cons_struct A τi τf) fs (H : length A = length fs) :
    is_Some (stlc_mu.lang.to_val (𝓕c pC fs)).
  Proof.
    induction pC; rewrite /𝓕c; asimpl; try destruct G; try by econstructor.
    assert (Hi : i < length fs). rewrite -H; apply lookup_lt_is_Some; by econstructor.
    destruct (fs !! i) eqn:Hf.
    rewrite (stlc_mu.typing.env_subst_lookup _ _ v).
    rewrite stlc_mu.lang.to_of_val.
    by econstructor.
    done.
    exfalso. assert (abs : length fs <= i). by apply lookup_ge_None. lia.
  Qed.

  Definition 𝓕cV {A} {τi τf} (pC : cons_struct A τi τf) fs (H : length A = length fs) : stlc_mu.lang.val :=
    is_Some_proj (𝓕c_is_value pC fs H).

  (** just redifine 𝓕C as value.. *)
  Lemma 𝓕c_rewrite {A} {τi τf} (pC : cons_struct A τi τf) fs (H : length A = length fs) : 𝓕c pC fs = stlc_mu.lang.of_val (𝓕cV pC fs H).
  Proof.
    unfold 𝓕cV.
    induction pC; rewrite /𝓕c; asimpl; try destruct G; try by econstructor.
    assert (Hi : i < length fs). rewrite -H; apply lookup_lt_is_Some; by econstructor.
    destruct (fs !! i) eqn:Hf.
    destruct (𝓕c_is_value
         (consTRecTRecUseCall A τl τr i pμτlμtrinA) fs H).
    admit.
    exfalso. assert (abs : length fs <= i). by apply lookup_ge_None. lia.
  Admitted.

  (** We will want to assume these functions to be meaningful..,
      i.e. they properly relate to the casts happening on the right side *)

  Definition rel_cast_functions A (fs : list stlc_mu.lang.val) : iProp Σ :=
    ⌜length A = length fs⌝ ∗
    [∗ list] a ; f ∈ A ; fs , (
                           □ (∀ (v : stlc_mu.lang.val) (v' : cast_calculus.lang.val) ,
                                 ⟦ a.1 ⟧ [] (v , v') → ⟦ a.2 ⟧ₑ [] ((stlc_mu.lang.of_val f v) , Cast (v') a.1 a.2))
                         )%I.

  Global Instance rel_cast_functions_persistent A fs :
    Persistent (rel_cast_functions A fs).
  Proof.
    apply bi.sep_persistent; first by apply bi.pure_persistent.
    apply big_sepL2_persistent. intros _ (τi , τf) f. simpl.
    apply bi.intuitionistically_persistent.
  Qed.

  (** The statement that the -- closed up -- back-translated casts behave appropriately.
      (We redefine it here to a new statement, making it a bit more amenable for proving.) *)

  Definition back_cast_ar {A} {τi τf} (pC : cons_struct A τi τf) :=
  ∀ ei' K' v v' fs, bi_entails
                      (rel_cast_functions A fs ∗ interp τi [] (v, v') ∗ initially_inv ei' ∗ currently_half (fill K' (Cast (cast_calculus.lang.of_val v') τi τf)))
                      (WP (𝓕c pC fs (stlc_mu.lang.of_val v)) {{ w, ∃ w', currently_half (fill K' (cast_calculus.lang.of_val w')) ∗ interp τf [] (w, w') }})%I.


End defs.
