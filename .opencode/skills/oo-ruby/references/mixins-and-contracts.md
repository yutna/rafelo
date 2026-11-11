# Mixins and Contracts

`VisitComplaint` and `BillingComplaint` are the two complaints the
clinic records: one about a visit, one about a bill. Both carry a
patient's name, the day the complaint arrived, and the subject they
name, and both need a summary line in the same shape. This file follows
one behaviour from a module that reads its hosts' instance variables to
an object each host holds, named by a Minitest contract.

## The mixin

```ruby
module DescribesComplaint
  def summary
    "#{@patient_name} complained on #{@received_on}: #{@subject}"
  end
end

class VisitComplaint
  include DescribesComplaint

  def initialize(patient_name, received_on, clinician)
    @patient_name = patient_name
    @received_on = received_on
    @subject = "the visit with #{clinician}"
  end
end

class BillingComplaint
  include DescribesComplaint

  def initialize(patient_name, received_on, invoice_number)
    @patient_name = patient_name
    @received_on = received_on
    @subject = "invoice #{invoice_number}"
  end
end

puts VisitComplaint.new("Ana", "2026-05-12", "Dr Okafor").summary
puts BillingComplaint.new("Bea", "2026-05-13", "INV-204").summary
```

In the first fence, `DescribesComplaint` is a module that reads
`@patient_name`, `@received_on` and `@subject` from the class that
includes it (rule 5). `VisitComplaint` and `BillingComplaint` each set
those variables, so the summary line names the patient, the day and
the subject; the module works only while both classes keep those
names, and a class that renames one cannot use it. Nothing names the
role the module assumes (rule 1). The fence stores nothing: it leaves
out where a complaint is saved, under which identity, and in which
transaction.

## A worked change

1. Name the role `ComplaintSummary` in a `ComplaintSummaryContract`
   module that every implementation's test class includes, as rule 1
   asks.
2. Move each host's wording into `VisitComplaintSummary` and
   `BillingComplaintSummary`, so each class answers `summary` from its
   own fields; the two lines stay the same.
3. Give `VisitComplaint` and `BillingComplaint` a summary object
   through their constructors and forward `summary` to it with
   `Forwardable`, as rule 5 asks.

```ruby
require "forwardable"

class VisitComplaintSummary
  def initialize(patient_name, received_on, clinician)
    @patient_name = patient_name
    @received_on = received_on
    @clinician = clinician
  end

  def summary
    "#{@patient_name} complained on #{@received_on}: " \
      "the visit with #{@clinician}"
  end
end

class BillingComplaintSummary
  def initialize(patient_name, received_on, invoice_number)
    @patient_name = patient_name
    @received_on = received_on
    @invoice_number = invoice_number
  end

  def summary
    "#{@patient_name} complained on #{@received_on}: " \
      "invoice #{@invoice_number}"
  end
end

class VisitComplaint
  extend Forwardable

  def_delegator :@summary, :summary

  def initialize(patient_name, received_on, clinician)
    @summary = VisitComplaintSummary.new(
      patient_name, received_on, clinician)
  end
end

class BillingComplaint
  extend Forwardable

  def_delegator :@summary, :summary

  def initialize(patient_name, received_on, invoice_number)
    @summary = BillingComplaintSummary.new(
      patient_name, received_on, invoice_number)
  end
end

puts VisitComplaint.new("Ana", "2026-05-12", "Dr Okafor").summary
puts BillingComplaint.new("Bea", "2026-05-13", "INV-204").summary
```

In the second fence, `VisitComplaintSummary` and
`BillingComplaintSummary` each answer `summary` from their own fields,
and the two lines are the same as the first fence's. `VisitComplaint`
and `BillingComplaint` hold a summary object, and `def_delegator`
writes one forwarding method for `summary`, so each class offers only
the message it means to offer and shares no instance variable with the
behaviour (rule 5). The contract in the next fence names the role those
two summaries play (rule 1). The fence stores nothing: it leaves out
where a complaint is saved, under which identity, and in which
transaction.

```ruby
require "minitest/autorun"

module ComplaintSummaryContract
  def test_summary_names_the_patient
    assert_includes build_summary.summary, "Ana"
  end

  def test_summary_names_the_day
    assert_includes build_summary.summary, "2026-05-12"
  end
end

class VisitComplaintSummaryTest < Minitest::Test
  include ComplaintSummaryContract

  def build_summary
    VisitComplaintSummary.new("Ana", "2026-05-12", "Dr Okafor")
  end
end

class BillingComplaintSummaryTest < Minitest::Test
  include ComplaintSummaryContract

  def build_summary
    BillingComplaintSummary.new("Ana", "2026-05-12", "INV-204")
  end
end
```

In the third fence, `ComplaintSummaryContract` names the role and holds
the tests every implementation must pass; `VisitComplaintSummaryTest`
and `BillingComplaintSummaryTest` each declare that their class plays
the role by including the module, so a second implementation joins by
adding its test class (rule 1). The tests send only `summary`, the
message a caller sends, and check only the answer a caller sees, so
they hold for both implementations. The fence stores nothing: it leaves
out where a complaint is saved, under which identity, and in which
transaction. The behaviour sits in an object each host holds, and each
host forwards one message to it, so the end state keeps rule 5.
